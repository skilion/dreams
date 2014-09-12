module dreams.world_mesh;

import dreams.world;
import std.concurrency;
import renderer, mesh, vector;

private enum tileSize = ushort.max / 16;

// struct that creates the chunk meshes
struct WorldMesh
{
	private const(WorldNode)* root;
	private uint maxCoord;

	Mesh mesh;
	alias mesh this;

	void setWorldRoot(const WorldNode* root)
	{
		assert(root);
		this.root = root;
		maxCoord = root.level * chunkSize * 2;
	}

	void create(const WorldChunk* chunk, uint x0, uint y0, uint z0)
	{
		mesh.clear();
		x0 &= ~chunkSizeMask;
		y0 &= ~chunkSizeMask;
		z0 &= ~chunkSizeMask;
		uint x1 = x0 + chunkSize;
		uint y1 = y0 + chunkSize;
		uint z1 = z0 + chunkSize;

		// helper function to retrieve the world blocks
		auto getBlock(uint x, uint y, uint z)
		{
			if (x >= maxCoord || y >= maxCoord || z >= maxCoord) {
				// out of range
				return WorldBlock();
			}
			if ((x ^ x0 & ~chunkSizeMask) == 0 && (y ^ y0 & ~chunkSizeMask) == 0 && (z ^ z0 & ~chunkSizeMask) == 0) {
				// the block is in the current chunk
				return chunk.getBlock(x, y, z);
			}
			return root.getBlock(x, y, z);
		}

		WorldBlock curr, back, front;
		for (uint x = x0; x < x1; x++) {
			float f_x = x - x0;
			for (uint y = y0; y < y1; y++) {
				float f_y = y - y0;
				back = getBlock(x, y, z0 - 1),
				curr = getBlock(x, y, z0);
				for (uint z = z0; z < z1; z++) {
					front = getBlock(x, y, z + 1);
					if (curr.isOpaque()) {
						float f_z = z - z0;
						uint visibleFaces = testVisibleFaces(
							getBlock(x - 1, y, z),
							getBlock(x + 1, y, z),
							getBlock(x, y - 1, z),
							getBlock(x, y + 1, z),
							back,
							front
						);
						addBlock(visibleFaces, f_x, f_y, f_z, curr.data0);
					}
					back = curr;
					curr = front;
				}
			}
		}
	}

	private void addBlock(uint visibleFaces, float x, float y, float z, ushort texture)
	{
		ushort s = (texture & 15) * tileSize; // texture % 16 * tileSize;
		ushort t = cast(ushort) ((texture >> 4) * tileSize); // texture / 16 * tileSize);
		int base = 0; // base index in blockVertices[]
		Vertex vertex;
		ushort faceVertices[4];
		foreach (face; 0 .. 6) {
			if (visibleFaces & 1) {
				foreach (i; 0 .. 4) { // foreach vertex
					vertex = blockVertices[base + i];
					vertex.position[0] += x;
					vertex.position[1] += y;
					vertex.position[2] += z;
					vertex.texcoord[0] += s;
					vertex.texcoord[1] += t;
					faceVertices[i] = addVertex(vertex);
				}
				indices ~= [
					faceVertices[0],
					faceVertices[1],
					faceVertices[2],
					faceVertices[0],
					faceVertices[2],
					faceVertices[3]
				];
			}
			base += 4; // 4 vertices for each face
			visibleFaces >>= 1; // next face
		}
	}
}

private uint testVisibleFaces(WorldBlock left, WorldBlock right, WorldBlock bottom, WorldBlock top, WorldBlock back, WorldBlock front)
{
	uint visibleFaces;
	if (left.isTransparent())   visibleFaces |= 0b000001;
	if (right.isTransparent())  visibleFaces |= 0b000010;
	if (bottom.isTransparent()) visibleFaces |= 0b000100;
	if (top.isTransparent())    visibleFaces |= 0b001000;
	if (back.isTransparent())   visibleFaces |= 0b010000;
	if (front.isTransparent())  visibleFaces |= 0b100000;
	return visibleFaces;
}

// mesh of a single block
enum a = 4;
enum b = tileSize - 4;
private immutable Vertex[24] blockVertices = [
	// left
	{[0, 0, 0], [-128, 0, 0, 0], [a, a], [127, 127, 127, 127]},
	{[0, 0, 1], [-128, 0, 0, 0], [b, a], [127, 127, 127, 127]},
	{[0, 1, 1], [-128, 0, 0, 0], [b, b], [127, 127, 127, 127]},
	{[0, 1, 0], [-128, 0, 0, 0], [a, b], [127, 127, 127, 127]},
	// right
	{[1, 0, 0], [127, 0, 0, 0], [b, a], [127, 127, 127, 127]},
	{[1, 1, 0], [127, 0, 0, 0], [b, b], [127, 127, 127, 127]},
	{[1, 1, 1], [127, 0, 0, 0], [a, b], [127, 127, 127, 127]},
	{[1, 0, 1], [127, 0, 0, 0], [a, a], [127, 127, 127, 127]},
	// bottom
	{[0, 0, 0], [0, -128, 0, 0], [a, a], [127, 127, 127, 127]},
	{[1, 0, 0], [0, -128, 0, 0], [b, a], [127, 127, 127, 127]},
	{[1, 0, 1], [0, -128, 0, 0], [b, b], [127, 127, 127, 127]},
	{[0, 0, 1], [0, -128, 0, 0], [a, b], [127, 127, 127, 127]},
	// top
	{[0, 1, 0], [0, 127, 0, 0], [a, a], [127, 127, 127, 127]},
	{[0, 1, 1], [0, 127, 0, 0], [b, a], [127, 127, 127, 127]},
	{[1, 1, 1], [0, 127, 0, 0], [b, b], [127, 127, 127, 127]},
	{[1, 1, 0], [0, 127, 0, 0], [a, b], [127, 127, 127, 127]},
	// back
	{[0, 0, 0], [0, 0, -128, 0], [b, a], [127, 127, 127, 127]},
	{[0, 1, 0], [0, 0, -128, 0], [b, b], [127, 127, 127, 127]},
	{[1, 1, 0], [0, 0, -128, 0], [a, b], [127, 127, 127, 127]},
	{[1, 0, 0], [0, 0, -128, 0], [a, a], [127, 127, 127, 127]},
	// front
	{[0, 0, 1], [0, 0, 127, 0], [a, a], [127, 127, 127, 127]},
	{[1, 0, 1], [0, 0, 127, 0], [b, a], [127, 127, 127, 127]},
	{[1, 1, 1], [0, 0, 127, 0], [b, b], [127, 127, 127, 127]},
	{[0, 1, 1], [0, 0, 127, 0], [a, b], [127, 127, 127, 127]},
];
