module dreams.imm3d;

import dreams.view;
import log, graphics, matrix, mesh, renderer, shaders, vector;

final class Immediate3D
{
private:
	Renderer renderer;
	IndexBuffer indexBuffer;
	VertexBuffer vertexBuffer;
	View view;
	TextureShader textureShader;
	byte[4] color = [127, 127, 127, 127];
	Texture texture;
	bool wireframe;
	Mesh mesh;

public:
	this(Renderer renderer)
	{
		assert(renderer, "Immediate3D.this: Null renderer");
		this.renderer = renderer;
	}

	void init()
	{
		indexBuffer = renderer.createIndexBuffer();
		vertexBuffer = renderer.createVertexBuffer();
		textureShader.init(renderer);
	}

	void shutdown()
	{
		renderer.destroyIndexBuffer(vertexBuffer);
		renderer.destroyVertexBuffer(indexBuffer);
	}

	void setView(const ref View view)
	{
		flush();
		this.view = view;
	}

	void setColor(byte r, byte g, byte b, byte a = 127)
	{
		this.color[0] = r;
		this.color[1] = g;
		this.color[2] = b;
		this.color[3] = a;
	}

	void setTexture(Texture texture)
	{
		flush();
		this.texture = texture;
	}

	void drawBasis(Vec3f position)
	{
		setTexture(0);
		setWireframe();
		with (position) {
			setColor(127, 0, 0);
			Index i0 = addVertex(x, y, z);
			Index i1 = addVertex(x + 1, y, z);
			setColor(0, 127, 0);
			Index i2 = addVertex(x, y, z);
			Index i3 = addVertex(x, y + 1, z);
			setColor(0, 0, 127);
			Index i4 = addVertex(x, y, z);
			Index i5 = addVertex(x, y, z + 1);
			mesh.indices ~= [i0, i0, i1, i2, i2, i3, i4, i4, i5];
		}
	}

	void drawWireframeBlock(float x0, float y0, float z0, float x1, float y1, float z1)
	{
		setTexture(0);
		setWireframe();
		Index i0 = addVertex(x0, y0, z0);
		Index i1 = addVertex(x1, y0, z0);
		Index i2 = addVertex(x0, y1, z0);
		Index i3 = addVertex(x1, y1, z0);
		Index i4 = addVertex(x0, y0, z1);
		Index i5 = addVertex(x1, y0, z1);
		Index i6 = addVertex(x0, y1, z1);
		Index i7 = addVertex(x1, y1, z1);
		Index blockIndices[36] = [
			i0, i0, i4, i4, i4, i6, i6, i6, i2, i2, i2, i0,
			i1, i1, i3, i3, i3, i7, i7, i7, i5, i5, i5, i1,
			i0, i0, i1, i4, i4, i5, i6, i6, i7, i2, i2, i3
		];
		mesh.indices ~= blockIndices;
	}

	void drawBillboard(Vec3f position, float width, float height)
	{
		unsetWireframe();
		auto f = (position - view.position).normalize();
		auto right = f.cross(Vec3f(0, 1, 0)).normalize();
		auto up =  right.cross(f) * (height * 0.5f);
		right *= width * 0.5f;
		Index i0 = addVertex(position - right - up, 0, 0);
		Index i1 = addVertex(position + right - up, ushort.max, 0);
		Index i2 = addVertex(position + right + up, ushort.max, ushort.max);
		Index i3 = addVertex(position - right + up, 0, ushort.max);
		mesh.indices ~= [i0, i1, i2, i2, i3, i0];
	}

	void drawYAlignedBillboard(Vec3f position, float width, float height)
	{
		unsetWireframe();
		auto f = (position - view.position).normalize();
		auto up = Vec3f(0, 1, 0);
		auto right = f.cross(up).normalize();
		up *=  height * 0.5f;
		right *= width * 0.5f;
		Index i0 = addVertex(position - right - up, 0, 0);
		Index i1 = addVertex(position + right - up, ushort.max, 0);
		Index i2 = addVertex(position + right + up, ushort.max, ushort.max);
		Index i3 = addVertex(position - right + up, 0, ushort.max);
		mesh.indices ~= [i0, i1, i2, i2, i3, i0];
	}

	void flush()
	{
		if (!mesh.indices.length) return;
		renderer.updateIndexBuffer(indexBuffer, mesh.indices, BufferUsage.streamDraw);
		renderer.updateVertexBuffer(vertexBuffer, mesh.vertices, BufferUsage.streamDraw);
		uint state;
		if (wireframe) state = RenderState.depthTest | RenderState.wireframe;
		else state = RenderState.cullFace | RenderState.depthTest;
		renderer.setState(state);
		renderer.setShader(textureShader.shader);
		textureShader.mvp.setMat4f(view.vp);
		if (texture == Texture.init) textureShader.textureMask.setFloat(0);
		else textureShader.textureMask.setFloat(1);
		textureShader.fixedColor.setVec4f(white);
		textureShader.texture.setInteger(0);
		renderer.draw(indexBuffer, cast(int) mesh.indices.length, vertexBuffer);
		mesh.clear();
	}

private:
	void setWireframe()
	{
		if (!wireframe) {
			flush();
			wireframe = true;
		}
	}

	void unsetWireframe()
	{
		if (wireframe) {
			flush();
			wireframe = false;
		}
	}

	Index addVertex(Vec3f vector, ushort s, ushort t)
	{
		Vertex v = {
			position: vector.array,
			texcoord: [s, t],
			color: this.color
		};
		return mesh.addVertex(v);
	}

	Index addVertex(float x, float y, float z)
	{
		Vertex v = {
		position: [x, y, z],
		color: this.color
		};
		return mesh.addVertex(v);
	}
}
