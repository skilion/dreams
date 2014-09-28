module renderer;

import gl.common;
import gl.core;
import std.stdio: File;
import std.string;
import cstr;
import engine;
import libimage;
import log;
import matrix;
import vector;

version (Windows)
{
	import windows.glwindow;
}
version (linux)
{
	import linux.glwindow;
}

enum RenderState: uint
{
	cullFace  = 0b001,
	depthTest = 0b010,
	wireframe = 0b100
}

enum TextureFormat
{
	rgb,
	rgba,
	alpha
}

enum TextureFilter
{
	nearest,
	atlas, // HACK: world texture
	bilinear,
	trilinear
}

enum TextureWrap
{
	repeat,
	clamp
}

enum BufferUsage
{
	staticDraw,
	dynamicDraw,
	streamDraw
}

private
{
	immutable GLenum[3] glTextureFormat = [GL_RGB, GL_RGBA, /*GL_LUMINANCE*/ 0x1909]; // HACK: OpenGL 2.0 does not support GL_RED
	immutable GLenum[4] glTextureMagFilter = [GL_NEAREST, GL_NEAREST, GL_LINEAR, GL_LINEAR];
	immutable GLenum[4] glTextureMinFilter = [GL_NEAREST, GL_NEAREST_MIPMAP_LINEAR, GL_LINEAR, GL_LINEAR_MIPMAP_LINEAR];
	immutable GLenum[2] glTextureWrap = [GL_REPEAT, GL_CLAMP_TO_EDGE];
	immutable GLenum[3] glBufferUsage = [GL_STATIC_DRAW, GL_DYNAMIC_DRAW, GL_STREAM_DRAW];
}

alias GLuint IndexBuffer;
alias GLuint VertexBuffer;
alias GLuint Texture;
alias ushort Index;

struct Vertex
{
	float[3]  position;
	byte[4]   normal;
	ushort[2] texcoord;
	byte[4]   color;
}

// shader's attribute indices
private
{
	immutable GLint attribPositionIndex = 0;
	immutable GLint attribNormalIndex   = 1;
	immutable GLint attribTexcoordIndex = 2;
	immutable GLint attribColorIndex    = 3;
}

private struct FxaaShader
{
	Shader shader;
	ShaderUniform texture;
	ShaderUniform inverseVP;

	void init(Renderer renderer)
	{
		shader = renderer.findShader("fxaa");
		texture = renderer.getShaderUniform(shader, "texture");
		inverseVP = renderer.getShaderUniform(shader, "inverseVP");
	}
}

private immutable float quadVertices[8] = [-1, -1, 1, -1, -1, 1, 1, 1];

final class Renderer
{
private:
	OpenGLWindow window;
	Shader[string] shaders;
	GLuint screenTexture; // texture for post-processing
	FxaaShader fxaaShader;
	GLuint quadVertexBuffer;

public:
	this(OpenGLWindow window)
	{
		assert(window);
		this.window = window;
	}

	void init()
	{
		printOpenGLInfo();
		glDepthFunc(GL_LEQUAL);
		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glEnableVertexAttribArray(attribPositionIndex);
		glEnableVertexAttribArray(attribNormalIndex);
		glEnableVertexAttribArray(attribTexcoordIndex);
		glEnableVertexAttribArray(attribColorIndex);
		// initialize screenTexture
		glGenTextures(1, &screenTexture);
		glBindTexture(GL_TEXTURE_2D, screenTexture);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, window.width, window.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, null);
		// initialize quad vertices
		glGenBuffers(1, &quadVertexBuffer);
		glBindBuffer(GL_ARRAY_BUFFER, quadVertexBuffer);
		glBufferData(GL_ARRAY_BUFFER, quadVertices.sizeof, quadVertices.ptr, GL_STATIC_DRAW);
		// TODO: window resizing...
		info("Preloading default shaders...");
		findShader("color");
		findShader("texture");
		findShader("alphatex");
		fxaaShader.init(this);
	}

	void shutdown()
	{
		foreach (shader; shaders) {
			shader.destroy();
		}
		destroy(shaders);
		glDeleteBuffers(1, &quadVertexBuffer);
		glDeleteTextures(1, &screenTexture);
	}

	void setState(uint state)
	{
		if (state & RenderState.cullFace) {
			glEnable(GL_CULL_FACE);
		} else {
			glDisable(GL_CULL_FACE);
		}
		if (state & RenderState.depthTest) {
			glEnable(GL_DEPTH_TEST);
		} else {
			glDisable(GL_DEPTH_TEST);
		}
		if (state & RenderState.wireframe) {
			glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
		} else {
			glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
		}
	}

	void getDisplayMode(ref int width, ref int height, ref bool fullscreen)
	{
		width = window.width;
		height = window.height;
		fullscreen = window.fullscreen;
	}

	/*
		Set the display resolution
		If the width or height is less than zero, the desktop resolution
		is used instead
	*/
	void setDisplayMode(int width, int height, bool fullscreen)
	{
		window.resize(width, height);
		window.fullscreen = fullscreen;
	}

	int getDpi()
	{
		// TODO
		return 96;
	}

	void beginFrame()
	{
		glClear(GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
	}

	void endFrame()
	{
		checkOpenGLError();
		window.swapBuffers();
	}

	void fxaa() // HACK: direct rederer call
	{
		checkOpenGLError();
		glDisable(GL_DEPTH_TEST);
		glDepthMask(GL_FALSE); // disable depth buffer writing
		glBindTexture(GL_TEXTURE_2D, screenTexture);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, window.width, window.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, null); // HACK
		glCopyTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, 0, 0, window.width, window.height);
		glClear(GL_COLOR_BUFFER_BIT);
		glBindTexture(GL_TEXTURE_2D, screenTexture);
		fxaaShader.shader.use();
		fxaaShader.texture.setInteger(0);
		fxaaShader.inverseVP.setVec2(1.0f / window.width, 1.0f / window.height);
		glBindBuffer(GL_ARRAY_BUFFER, quadVertexBuffer);
		glVertexAttribPointer(attribPositionIndex, 2, GL_FLOAT, GL_FALSE, 0, null);
		glDisableVertexAttribArray(attribNormalIndex);
		glDisableVertexAttribArray(attribTexcoordIndex);
		glDisableVertexAttribArray(attribColorIndex);
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		glEnableVertexAttribArray(attribNormalIndex);
		glEnableVertexAttribArray(attribTexcoordIndex);
		glEnableVertexAttribArray(attribColorIndex);
		glDepthMask(GL_TRUE); // enable depth buffer writing
		glEnable(GL_DEPTH_TEST);
	}

	Shader findShader(string name)
	{
		auto p = name in shaders;
		if (!p) {
			Shader shader = new Shader;
			shader.create("shaders/" ~ name);
			return shaders[name] = shader;
		}
		return *p;
	}

	ShaderUniform getShaderUniform(Shader shader, string name)
	{
		return shader.getUniform(name);
	}

	void setShader(Shader shader)
	{
		shader.use();
	}

	VertexBuffer createVertexBuffer()
	{
		GLuint vertexBuffer;
		glGenBuffers(1, &vertexBuffer);
		return vertexBuffer;
	}

	void updateVertexBuffer(VertexBuffer vertexBuffer, const(Vertex)[] vertices, BufferUsage bufferUsage)
	{
		glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
		glBufferData(GL_ARRAY_BUFFER, Vertex.sizeof * vertices.length, vertices.ptr, glBufferUsage[bufferUsage]);
	}

	void destroyVertexBuffer(VertexBuffer vertexBuffer)
	{
		glDeleteBuffers(1, &vertexBuffer);
	}

	IndexBuffer createIndexBuffer()
	{
		GLuint indexBuffer;
		glGenBuffers(1, &indexBuffer);
		return indexBuffer;
	}

	void updateIndexBuffer(IndexBuffer indexBuffer, const(Index)[] indices, BufferUsage bufferUsage)
	{
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
		glBufferData(GL_ELEMENT_ARRAY_BUFFER, Index.sizeof * indices.length, indices.ptr, glBufferUsage[bufferUsage]);
	}

	void destroyIndexBuffer(IndexBuffer indexBuffer)
	{
		glDeleteBuffers(1, &indexBuffer);
	}

	Texture loadTexture(string filename, TextureFilter filter, TextureWrap wrap)
	{
		Image image;
		ImgError e = imgLoad(toStringz("textures/" ~ filename), &image);
		final switch (e)
		{
		case ImgError.IMG_NOT_FOUND:
			error("Image not found: %s", filename);
			break;
		case ImgError.IMG_ERROR:
			error("Error while loading the image: %s", filename);
			break;
		case ImgError.IMG_UNSUPPORTED:
			error("Unsupported image: %s", filename);
			break;
		case ImgError.IMG_NO_ERROR:
			break;
		}
		Texture texture = createTexture(
			image.data,
			image.width,
			image.height,
			cast(TextureFormat) image.format, // the values are identical
			filter,
			wrap
		);
		imgFree(&image);
		return texture;
	}

	Texture createTexture(void* data, int width, int height, TextureFormat format, TextureFilter filter, TextureWrap wrap)
	{
		Texture texture;
		glGenTextures(1, &texture);
		glBindTexture(GL_TEXTURE_2D, texture);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, glTextureMagFilter[filter]);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, glTextureMinFilter[filter]);
		if (filter == TextureFilter.atlas) {
			glTexParameteri(GL_TEXTURE_2D, /*GL_GENERATE_MIPMAP*/ 0x8191, GL_TRUE);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAX_LEVEL, 4); // HACK: prevent small mipmaps
		}
		if (filter == TextureFilter.trilinear) {
			// HACK: legacy mipmap generation method to not rely on GL_ARB_framebuffer_object
			glTexParameteri(GL_TEXTURE_2D, /*GL_GENERATE_MIPMAP*/ 0x8191, GL_TRUE);
		}
		glTexImage2D(
			GL_TEXTURE_2D,
			0,
			glTextureFormat[format],
			width,
			height,
			0,
			glTextureFormat[format],
			GL_UNSIGNED_BYTE,
			data
		);
		return texture;
	}

	void updateTexture(Texture texture, void* data, int width, int height, TextureFormat format)
	{
		glBindTexture(GL_TEXTURE_2D, texture);
		glTexImage2D(
			GL_TEXTURE_2D,
			0,
			glTextureFormat[format],
			width,
			height,
			0,
			glTextureFormat[format],
			GL_UNSIGNED_BYTE,
			data
		);
	}

	void setTexture(Texture texture)
	{
		glActiveTexture(GL_TEXTURE0);
		glBindTexture(GL_TEXTURE_2D, texture);
	}

	void destroyTexture(Texture texture)
	{
		glDeleteTextures(1, &texture);
	}

	void destroyTextures(Texture[] texture)
	{
		glDeleteTextures(cast(GLsizei) texture.length, texture.ptr);
	}

	void draw(IndexBuffer indexBuffer, int indexCount, VertexBuffer vertexBuffer)
	{
		glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
		glVertexAttribPointer(attribPositionIndex, 3, GL_FLOAT,          GL_FALSE, Vertex.sizeof, cast(void*) Vertex.position.offsetof);
		glVertexAttribPointer(attribNormalIndex,   4, GL_BYTE,           GL_TRUE,  Vertex.sizeof, cast(void*) Vertex.normal.offsetof  );
		glVertexAttribPointer(attribTexcoordIndex, 2, GL_UNSIGNED_SHORT, GL_TRUE,  Vertex.sizeof, cast(void*) Vertex.texcoord.offsetof);
		glVertexAttribPointer(attribColorIndex,    4, GL_BYTE,           GL_TRUE,  Vertex.sizeof, cast(void*) Vertex.color.offsetof   );
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
		glDrawElements(GL_TRIANGLES, indexCount, GL_UNSIGNED_SHORT, null);
	}
}

final class Shader
{
private:
	string filename; // without extension
	GLuint program;
	ShaderUniform[string] uniforms;

	static immutable string[] attribs = ["position", "normal", "texcoord", "color"];
	static immutable GLint[] attribIndex = [0, 1, 2, 3];

	/*
		Loads the shader from a file.
		The filename must be supplied without extension.
	*/
	void create(string filename)
	{
		this.filename = filename;
		program = glCreateProgram();
		reload();
	}

	void destroy()
	{
		glDeleteProgram(program);
		filename.length = 0;
		program = 0;
	}

	ShaderUniform getUniform(const(char)[] name)
	{
		return uniforms[name];
	}

	void use()
	{
		glUseProgram(program);
	}

public:
	void reload()
	{
		.destroy(uniforms); // remove any previous uniform
		GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
		GLuint fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);

		// compile
		loadShader(vertexShader, filename ~ ".vsh");
		loadShader(fragmentShader, filename ~ ".fsh");
		glAttachShader(program, vertexShader);
		glAttachShader(program, fragmentShader);
		glDeleteShader(vertexShader);
		glDeleteShader(fragmentShader);

		// set attribute indices
		foreach (i, attrib; attribs)
		{
			glBindAttribLocation(program, attribIndex[i], attrib.ptr);
		}

		// link
		GLint linked;
		glLinkProgram(program);
		glDetachShader(program, vertexShader);
		glDetachShader(program, fragmentShader);
		glGetProgramiv(program, GL_LINK_STATUS, &linked);

		const(GLchar)[] infoLog = getProgramInfoLog(program);
		if (!linked)
		{
			fatal("Shader.link: Linking of shader program \"%s\" failed:\n%s", filename, infoLog);
		}
		if (infoLog.length > 0)
		{
			dev("Shader.link: Shader program \"%s\" linking log:\n%s", filename, infoLog);
		}

		// gets all available uniforms
		ShaderUniform uniform;
		GLint uniformSize;
		GLchar[] uniformName;
		GLint uniformCount, uniformNameMaxLength;
		glGetProgramiv(program, GL_ACTIVE_UNIFORMS, &uniformCount);
		glGetProgramiv(program, GL_ACTIVE_UNIFORM_MAX_LENGTH, &uniformNameMaxLength);
		uniformName = new GLchar[uniformNameMaxLength];
		foreach (uniformIndex; 0 .. uniformCount)
		{
			glGetActiveUniform(
				program,
				cast(GLuint) uniformIndex,
				uniformNameMaxLength,
				null,
				&uniformSize,
				&uniform.type,
				uniformName.ptr
			);
			uniform.location = glGetUniformLocation(program, uniformName.ptr);
			uniforms[cstr2dstr(uniformName.ptr).idup] = uniform;
		}
	}
}

struct ShaderUniform
{
private:
	GLint location;
	GLenum type;

public:
	void setInteger(int value)
	{
		assert(type == GL_INT || type == GL_SAMPLER_2D);
		glUniform1i(location, value);
	}

	void setFloat(float value)
	{
		assert(type == GL_FLOAT);
		glUniform1f(location, value);
	}

	void setVec2(float x, float y)
	{
		assert(type == GL_FLOAT_VEC2);
		glUniform2f(location, x, y);
	}

	void setVec3f(const ref Vec3f vector)
	{
		assert(type == GL_FLOAT_VEC3);
		glUniform3fv(location, 1, vector.ptr);
	}

	void setVec4f(const ref Vec4f vector)
	{
		assert(type == GL_FLOAT_VEC4);
		glUniform4fv(location, 1, vector.ptr);
	}

	void setMat4f(const ref Mat4f matrix)
	{
		assert(type == GL_FLOAT_MAT4);
		glUniformMatrix4fv(location, 1, GL_FALSE, matrix.ptr);
	}
}

private void loadShader(GLuint shader, string filename)
{
	assert(shader != 0, "loadShader: Shader 0 is not valid");

	File file = File(filename, "r");
	GLchar[] source = new GLchar[cast(size_t) file.size()];
	file.rawRead(source);
	file.close;

	GLchar* ptr = source.ptr;
	GLsizei length = cast(GLsizei) source.length;
	glShaderSource(shader, 1, &ptr, &length);
	destroy(source);

	GLint compiled = void;
	glCompileShader(shader);
	glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
	const(GLchar)[] infoLog = getShaderInfoLog(shader);
	if (!compiled)
	{
		fatal("loadShader: Compilation of shader \"%s\" failed:\n%s", filename, infoLog);
	}
	if (infoLog.length > 0)
	{
		dev("loadShader: Shader \"%s\" compilation log:\n%s", filename, infoLog);
	}
}

private const(GLchar)[] getShaderInfoLog(GLuint shader)
{
	GLsizei length = void;
	glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &length);
	if (length <= 1) return "";
	GLchar[] log = new GLchar[length];
	glGetShaderInfoLog(shader, length, &length, log.ptr);
	return log;
}

private const(GLchar)[] getProgramInfoLog(GLuint program)
{
	GLsizei length = void;
	glGetProgramiv(program, GL_INFO_LOG_LENGTH, &length);
	if (length <= 1) return "";
	GLchar[] log = new GLchar[length];
	glGetProgramInfoLog(program, length, &length, log.ptr);
	return log[0 .. length];
}
