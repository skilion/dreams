module dreams.skybox;

import dreams.view;
import std.math;
import renderer, matrix, vector;

struct SkyboxShader
{
	Shader shader;
	ShaderUniform mvp;
	ShaderUniform texture;

	void init(Renderer renderer)
	{
		shader = renderer.findShader("skybox");
		mvp = renderer.getShaderUniform(shader, "mvp");
		texture = renderer.getShaderUniform(shader, "texture");
	}
}

// cube drawn around the viewer
struct Skybox
{
	Renderer renderer;
	SkyboxShader skyboxShader;
	IndexBuffer indexBuffer;
	VertexBuffer vertexBuffer;
	Texture[2] textures;
	int texnum;
	Mat4f m; // additional matrix for external effects

	void init(Renderer renderer)
	{
		assert(renderer);
		this.renderer = renderer;
		skyboxShader.init(renderer);
		indexBuffer = renderer.createIndexBuffer();
		vertexBuffer = renderer.createVertexBuffer();
		renderer.updateIndexBuffer(indexBuffer, skyboxIndices, BufferUsage.staticDraw);
		renderer.updateVertexBuffer(vertexBuffer, skyboxVertices, BufferUsage.staticDraw);
		textures[0] = renderer.loadTexture("skybox0.png", TextureFilter.nearest, TextureWrap.clamp);
		textures[1] = renderer.loadTexture("skybox1.png", TextureFilter.nearest, TextureWrap.clamp);
	}

	void shutdown()
	{
		renderer.destroyTextures(textures);
		renderer.destroyIndexBuffer(indexBuffer);
		renderer.destroyVertexBuffer(vertexBuffer);
	}

	void render(const ref View view)
	{
		renderer.setState(RenderState.cullFace | RenderState.depthTest);
		renderer.setShader(skyboxShader.shader);
		skyboxShader.texture.setInteger(0);
		auto translation = translationMatrix(view.position.x, view.position.y, view.position.z);
		auto mvp = view.vp * translation * m;
		skyboxShader.mvp.setMat4f(mvp);
		renderer.setTexture(textures[texnum]);
		renderer.draw(indexBuffer, skyboxIndices.length, vertexBuffer);
	}
}

private enum k = ushort.max / 16;
private immutable Vertex[24] skyboxVertices = [
	// front
	{[-10, -10, -10], [0, 0, 127, 0], [k * 4, k * 6], [127, 127, 127, 127]},
	{[+10, -10, -10], [0, 0, 127, 0], [k * 8, k * 6], [127, 127, 127, 127]},
	{[+10, +10, -10], [0, 0, 127, 0], [k * 8, k * 10], [127, 127, 127, 127]},
	{[-10, +10, -10], [0, 0, 127, 0], [k * 4, k * 10], [127, 127, 127, 127]},
	// back
	{[-10, -10, +10], [0, 0, -128, 0], [k * 12, k * 6], [127, 127, 127, 127]},
	{[-10, +10, +10], [0, 0, -128, 0], [k * 12, k * 10], [127, 127, 127, 127]},
	{[+10, +10, +10], [0, 0, -128, 0], [k * 16, k * 10], [127, 127, 127, 127]},
	{[+10, -10, +10], [0, 0, -128, 0], [k * 16, k * 6], [127, 127, 127, 127]},
	// left
	{[-10, -10, -10], [127, 0, 0, 0], [k * 4, k * 6], [127, 127, 127, 127]},
	{[-10, +10, -10], [127, 0, 0, 0], [k * 4, k * 10], [127, 127, 127, 127]},
	{[-10, +10, +10], [127, 0, 0, 0], [k * 0, k * 10], [127, 127, 127, 127]},
	{[-10, -10, +10], [127, 0, 0, 0], [k * 0, k * 6], [127, 127, 127, 127]},
	// right
	{[+10, -10, -10], [-128, 0, 0, 0], [k * 8, k * 6], [127, 127, 127, 127]},
	{[+10, -10, +10], [-128, 0, 0, 0], [k * 12, k * 6], [127, 127, 127, 127]},
	{[+10, +10, +10], [-128, 0, 0, 0], [k * 12, k * 10], [127, 127, 127, 127]},
	{[+10, +10, -10], [-128, 0, 0, 0], [k * 8, k * 10], [127, 127, 127, 127]},
	// below
	{[-10, -10, -10], [0, 127, 0, 0], [k * 4, k * 6], [127, 127, 127, 127]},
	{[-10, -10, +10], [0, 127, 0, 0], [k * 4, k * 2], [127, 127, 127, 127]},
	{[+10, -10, +10], [0, 127, 0, 0], [k * 8, k * 2], [127, 127, 127, 127]},
	{[+10, -10, -10], [0, 127, 0, 0], [k * 8, k * 6], [127, 127, 127, 127]},
	// above
	{[-10, +10, -10], [0, -128, 0, 0], [k * 4, k * 10], [127, 127, 127, 127]},
	{[+10, +10, -10], [0, -128, 0, 0], [k * 8, k * 10], [127, 127, 127, 127]},
	{[+10, +10, +10], [0, -128, 0, 0], [k * 8, k * 14], [127, 127, 127, 127]},
	{[-10, +10, +10], [0, -128, 0, 0], [k * 4, k * 14], [127, 127, 127, 127]},
];

private immutable Index[36] skyboxIndices = [
	0, 1, 2, 2, 3, 0,
	4, 5, 6, 6, 7, 4,
	8, 9, 10, 10, 11, 8,
	12, 13, 14, 14, 15, 12,
	16, 17, 18, 18, 19, 16,
	20, 21, 22, 22, 23, 20,
];
