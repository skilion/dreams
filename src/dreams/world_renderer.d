module dreams.world_renderer;

import core.thread;
import dreams.culling, dreams.view, dreams.world, dreams.world_mesh;
import std.datetime.stopwatch: StopWatch;
import std.concurrency, std.exception, std.math;
import log, matrix, renderer, vector;

struct WorldShader
{
	Shader shader;
	ShaderUniform mvp;
	ShaderUniform texture;

	void init(Renderer renderer)
	{
		shader = renderer.findShader("world");
		mvp = renderer.getShaderUniform(shader, "mvp");
		texture = renderer.getShaderUniform(shader, "texture");
	}
}

enum mesherThreadsNum = 8; // TODO: configurable var

final class WorldRenderer
{
	private Renderer renderer;
	private WorldShader worldShader;
	public Texture worldTexture; //public to show the tiles in the editor

	private Tid[] mesherThreads;
	private uint nextMesher; // index of the mesher thread to use (to enable workload sharing)

	private WorldNode* root;
	private Vec3f position; // viewer position
	private Mat4f vp; // view-projection matrix
	private RadarTest frustumCulling;

	private WorldChunk*[] chunksToBeRendered;

	enum size_t maxChunkMeshMem = 64 * 2 ^^ 20;
	size_t chunkMeshMem;
	int chunkMeshCount;
	WorldChunk* first, last; // list of chunks with an allocated mesh

	this(Renderer renderer)
	{
		assert(renderer);
		this.renderer = renderer;
		chunksToBeRendered.reserve(512);
	}

	void init()
	{
		worldShader.init(renderer);
		worldTexture = renderer.loadTexture("world.png", TextureFilter.atlas, TextureWrap.clamp);
	}

	void shutdown()
	{
		asyncStopMesherThreads();
		destroyAllMeshes();
		renderer.destroyTexture(worldTexture);
	}

	void setWorldRoot(WorldNode* root)
	{
		if (this.root != root) {
			asyncStopMesherThreads();
			this.root = root;
			destroyAllMeshes();
			mesherThreads.length = 0;
			assumeSafeAppend(mesherThreads);
			for (int i = 0; i < mesherThreadsNum; i++) {
				mesherThreads ~= spawn(&mesherThread, cast(immutable WorldNode*) root);
			}
		}
	}

	void setView(const ref View view)
	{
		this.position = view.position;
		this.vp = view.vp;
		with (view) {
			frustumCulling.set(position, forward, side, up, aspect, near, far, fov);
		}
	}

	void render()
	{
		StopWatch sw;
		sw.start();
		while (receiveTimeout(msecs(-1), &onChunkMeshReady)) {
			if (sw.peek() >= msecs(5)) {
				break;
			}
		}

		chunksToBeRendered.length = 0;
		assumeSafeAppend(chunksToBeRendered);
		findVisibleChunks(root);
		drawChunks();

		while (chunkMeshMem > maxChunkMeshMem) {
			chunkMeshMem -= first.meshSize;
			chunkMeshCount--;
			first.needUpdate = true;
			first.meshSize = 0;
			renderer.destroyVertexBuffer(first.vertexBuffer);
			renderer.destroyIndexBuffer(first.indexBuffer);
			first.indexBuffer = IndexBuffer.init;
			first.vertexBuffer = VertexBuffer.init;
			//dev("Chunk %s mesh deleted", first.position.array);
			first.next.prev = null;
			WorldChunk* next = first.next;
			first.prev = first.next = null;
			first = next;
		}
	}

	void destroyAllMeshes()
	{
		WorldChunk* chunk = first;
		while (chunk) {
			chunk.needUpdate = true;
			chunk.waitingMesher = false;
			chunk.meshSize = 0;
			renderer.destroyIndexBuffer(chunk.indexBuffer);
			renderer.destroyVertexBuffer(chunk.vertexBuffer);
			chunk.indexBuffer = IndexBuffer.init;
			chunk.vertexBuffer = VertexBuffer.init;
			WorldChunk* next = chunk.next;
			chunk.prev = chunk.next = null; // remove from the list
			chunk = next;
		}
		chunkMeshMem = 0;
		chunkMeshCount = 0;
	}

	private void findVisibleChunks(WorldNode* node)
	{
		immutable float sqrt3 = 1.73205080f;
		if (frustumCulling.sphereTest(node.center, node.getExtent() * sqrt3)) {
			if (node.level == 1) 	{
				foreach (chunk; node.chunks) {
					if (chunk) {
						immutable adjust = Vec3f(chunkSize / 2, chunkSize / 2, chunkSize / 2);
						Vec3f chunkCenter = chunk.position + adjust;
						immutable float chunkRadius = chunkSize / 2 * sqrt3;
						if (frustumCulling.sphereTest(chunkCenter, chunkRadius)) {
							addVisibleChunk(chunk);
						}
					}
				}
			} else {
				foreach (child; node.nodes) {
					if (child) findVisibleChunks(child);
				}
			}
		}
	}

	private void addVisibleChunk(WorldChunk* chunk)
	{
		if ((chunk.indexBuffer == 0 || chunk.needUpdate == true) && !chunk.waitingMesher) {
			chunk.waitingMesher = true;
			asyncCreateChunkMesh(
				chunk,
				cast(uint) chunk.position.x,
				cast(uint) chunk.position.y,
				cast(uint) chunk.position.z
			);
		}
		if (chunk.indexBuffer != 0) {
			chunksToBeRendered ~= chunk;
		}
	}

	private void drawChunks()
	{
		Mat4f mvp;
		renderer.setState(RenderState.cullFace | RenderState.depthTest);
		renderer.setShader(worldShader.shader);
		renderer.setTexture(worldTexture);
		worldShader.texture.setInteger(0);
		foreach (chunk; chunksToBeRendered) {
			auto translation =  translationMatrix(
				chunk.position.x,
				chunk.position.y,
				chunk.position.z
			);
			mvp = vp * translation;
			worldShader.mvp.setMat4f(mvp);
			renderer.draw(chunk.indexBuffer, chunk.indexCount, chunk.vertexBuffer);
		}
	}

	private void asyncCreateChunkMesh(WorldChunk* chunk, uint x, uint y, uint z)
	{
		send(mesherThreads[nextMesher++], cast(immutable WorldChunk*) chunk, x, y, z);
		//dev("asyncCreateChunkMesh %s", chunk.position.array);
		if (nextMesher == mesherThreads.length) {
			nextMesher = 0;
		}
	}

	private void asyncStopMesherThreads()
	{
		foreach (tid; mesherThreads) {
			prioritySend(tid, 0);
		}
	}

	private void onChunkMeshReady(immutable(WorldChunk)* chunk_, immutable(WorldMesh)* mesh_, Tid tid)
	{
		//dev("onChunkMeshReady %s", chunk_.position.array);
		WorldChunk* chunk = cast(WorldChunk*) chunk_;
		WorldMesh* mesh = cast(WorldMesh*) mesh_;
		// TODO: should check if asyncStopMesherThreads has been called ...
		if (!(chunk.prev || chunk.next)) {
			// add the chunk to the list
			if (!first) { // list empty
				first = last = chunk;
			} else {
				last.next = chunk;
				chunk.prev = last;
				last = chunk;
			}
			chunkMeshCount++;
		} else {
			// move the chunk to the last position in the list
			if (last != chunk) {
				if (chunk.prev) chunk.prev.next = chunk.next;
				else first = chunk.next;
				chunk.next.prev = chunk.prev;
				last.next = chunk;
				chunk.prev = last;
				chunk.next = null;
				last = chunk;
			}
		}

		chunkMeshMem -= chunk.meshSize;
		chunk.needUpdate = false;
		chunk.waitingMesher = false;
		if (!chunk.indexBuffer) chunk.indexBuffer = renderer.createIndexBuffer();
		if (!chunk.vertexBuffer) chunk.vertexBuffer = renderer.createVertexBuffer();
		renderer.updateIndexBuffer(chunk.indexBuffer, mesh.indices, BufferUsage.staticDraw);
		chunk.indexCount = cast(int) mesh.indices.length;
		renderer.updateVertexBuffer(chunk.vertexBuffer, mesh.vertices, BufferUsage.staticDraw);
		chunk.meshSize = mesh.indices.length * Index.sizeof + mesh.vertices.length * Vertex.sizeof;
		send(tid, 0); // unlock the mesher
		chunkMeshMem += chunk.meshSize;
		//dev("Chunk %s mesh updated", chunk.position.array);
	}
}

/*
	Mesher thread
*/
private void mesherThread(immutable(WorldNode)* root)
{
	WorldMesh worldMesh;
	worldMesh.reserve(2048);
	worldMesh.setWorldRoot(root);

	void createMesh(immutable(WorldChunk)* chunk, uint x, uint y, uint z) {
		worldMesh.create(chunk, x, y, z);
		//dev("mesherThread send  %s", chunk.position.array);
		send(ownerTid(), chunk, cast(immutable WorldMesh*) &worldMesh, thisTid());
		receive((int i) {}); // wait till the renderer thread has processed the mesh
	}

	bool running = true;
	while (running) {
		receive(
			&createMesh,
			(int) { running = false; },
			(OwnerTerminated e) { running = false; }
		);
	}
}
