module shaders;

import renderer;

struct TextureShader
{
	Shader shader;
	ShaderUniform mvp;
	ShaderUniform textureMask;
	ShaderUniform fixedColor;
	ShaderUniform texture;

	void init(Renderer renderer)
	{
		shader = renderer.findShader("texture");
		mvp = renderer.getShaderUniform(shader, "mvp");
		textureMask = renderer.getShaderUniform(shader, "textureMask");
		fixedColor = renderer.getShaderUniform(shader, "fixedColor");
		texture = renderer.getShaderUniform(shader, "texture");
	}
}

struct AlphaTexShader
{
	Shader shader;
	ShaderUniform mvp;
	ShaderUniform fixedColor;
	ShaderUniform texture;

	void init(Renderer renderer)
	{
		shader = renderer.findShader("alphatex");
		mvp = renderer.getShaderUniform(shader, "mvp");
		fixedColor = renderer.getShaderUniform(shader, "fixedColor");
		texture = renderer.getShaderUniform(shader, "texture");
	}
}
