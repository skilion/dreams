module gl.ext;

import core.stdc.string;
import gl.common, gl.core;
import cstr, log;

version (Windows)
{
	import windows.glloader: glGetProcAddress;
}
version (linux)
{
	import linux.glloader: glGetProcAddress;
}

void loadOpenGLExtensions()
{
	scope (failure) return;
	if (isGLExtSupported("GL_ARB_framebuffer_object")) {
		glIsRenderbuffer = cast(PFNGLISRENDERBUFFERPROC) glGetProcAddress("glIsRenderbuffer");
		glBindRenderbuffer = cast(PFNGLBINDRENDERBUFFERPROC) glGetProcAddress("glBindRenderbuffer");
		glDeleteRenderbuffers = cast(PFNGLDELETERENDERBUFFERSPROC) glGetProcAddress("glDeleteRenderbuffers");
		glGenRenderbuffers = cast(PFNGLGENRENDERBUFFERSPROC) glGetProcAddress("glGenRenderbuffers");
		glRenderbufferStorage = cast(PFNGLRENDERBUFFERSTORAGEPROC) glGetProcAddress("glRenderbufferStorage");
		glGetRenderbufferParameteriv = cast(PFNGLGETRENDERBUFFERPARAMETERIVPROC) glGetProcAddress("glGetRenderbufferParameteriv");
		glIsFramebuffer = cast(PFNGLISFRAMEBUFFERPROC) glGetProcAddress("glIsFramebuffer");
		glBindFramebuffer = cast(PFNGLBINDFRAMEBUFFERPROC) glGetProcAddress("glBindFramebuffer");
		glDeleteFramebuffers = cast(PFNGLDELETEFRAMEBUFFERSPROC) glGetProcAddress("glDeleteFramebuffers");
		glGenFramebuffers = cast(PFNGLGENFRAMEBUFFERSPROC) glGetProcAddress("glGenFramebuffers");
		glCheckFramebufferStatus = cast(PFNGLCHECKFRAMEBUFFERSTATUSPROC) glGetProcAddress("glCheckFramebufferStatus");
		glFramebufferTexture1D = cast(PFNGLFRAMEBUFFERTEXTURE1DPROC) glGetProcAddress("glFramebufferTexture1D");
		glFramebufferTexture2D = cast(PFNGLFRAMEBUFFERTEXTURE2DPROC) glGetProcAddress("glFramebufferTexture2D");
		glFramebufferTexture3D = cast(PFNGLFRAMEBUFFERTEXTURE3DPROC) glGetProcAddress("glFramebufferTexture3D");
		glFramebufferRenderbuffer = cast(PFNGLFRAMEBUFFERRENDERBUFFERPROC) glGetProcAddress("glFramebufferRenderbuffer");
		glGetFramebufferAttachmentParameteriv = cast(PFNGLGETFRAMEBUFFERATTACHMENTPARAMETERIVPROC) glGetProcAddress("glGetFramebufferAttachmentParameteriv");
		glGenerateMipmap = cast(PFNGLGENERATEMIPMAPPROC) glGetProcAddress("glGenerateMipmap");
		glBlitFramebuffer = cast(PFNGLBLITFRAMEBUFFERPROC) glGetProcAddress("glBlitFramebuffer");
		glRenderbufferStorageMultisample = cast(PFNGLRENDERBUFFERSTORAGEMULTISAMPLEPROC) glGetProcAddress("glRenderbufferStorageMultisample");
		glFramebufferTextureLayer = cast(PFNGLFRAMEBUFFERTEXTURELAYERPROC) glGetProcAddress("glFramebufferTextureLayer");
		GL_ARB_framebuffer_object = true;
	}
	if (isGLExtSupported("GL_EXT_framebuffer_multisample")) {
		glRenderbufferStorageMultisampleEXT = cast(PFNGLRENDERBUFFERSTORAGEMULTISAMPLEEXTPROC) glGetProcAddress("glRenderbufferStorageMultisampleEXT");
		GL_EXT_framebuffer_multisample = true;
	}
}

void unloadOpenGLExtensions() nothrow
{
	GL_ARB_framebuffer_object = false;
	GL_EXT_framebuffer_multisample = false;
}

// extension must be a null terminated string
private bool isGLExtSupported(const(char)* extension)
{
	auto extensionList = cast(const(char)*) glGetString(GL_EXTENSIONS);
	if (isExtSupported(extension, extensionList)) {
		info("GL Extension found: %s", cstr2dstr(extension));
		return true;
	}
	warning("GL Extension not found: %s", cstr2dstr(extension));
	return false;
}

extern (System) __gshared nothrow:

// GL_ARB_framebuffer_object
bool GL_ARB_framebuffer_object = false;
enum GL_INVALID_FRAMEBUFFER_OPERATION = 0x0506;
enum GL_FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING = 0x8210;
enum GL_FRAMEBUFFER_ATTACHMENT_COMPONENT_TYPE = 0x8211;
enum GL_FRAMEBUFFER_ATTACHMENT_RED_SIZE = 0x8212;
enum GL_FRAMEBUFFER_ATTACHMENT_GREEN_SIZE = 0x8213;
enum GL_FRAMEBUFFER_ATTACHMENT_BLUE_SIZE = 0x8214;
enum GL_FRAMEBUFFER_ATTACHMENT_ALPHA_SIZE = 0x8215;
enum GL_FRAMEBUFFER_ATTACHMENT_DEPTH_SIZE = 0x8216;
enum GL_FRAMEBUFFER_ATTACHMENT_STENCIL_SIZE = 0x8217;
enum GL_FRAMEBUFFER_DEFAULT = 0x8218;
enum GL_FRAMEBUFFER_UNDEFINED = 0x8219;
enum GL_DEPTH_STENCIL_ATTACHMENT = 0x821A;
enum GL_INDEX = 0x8222;
enum GL_MAX_RENDERBUFFER_SIZE = 0x84E8;
enum GL_DEPTH_STENCIL = 0x84F9;
enum GL_UNSIGNED_INT_24_8 = 0x84FA;
enum GL_DEPTH24_STENCIL8 = 0x88F0;
enum GL_TEXTURE_STENCIL_SIZE = 0x88F1;
enum GL_FRAMEBUFFER_BINDING = 0x8CA6;
enum GL_DRAW_FRAMEBUFFER_BINDING = GL_FRAMEBUFFER_BINDING;
enum GL_RENDERBUFFER_BINDING = 0x8CA7;
enum GL_READ_FRAMEBUFFER = 0x8CA8;
enum GL_DRAW_FRAMEBUFFER = 0x8CA9;
enum GL_READ_FRAMEBUFFER_BINDING = 0x8CAA;
enum GL_RENDERBUFFER_SAMPLES = 0x8CAB;
enum GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE = 0x8CD0;
enum GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME = 0x8CD1;
enum GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL = 0x8CD2;
enum GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE = 0x8CD3;
enum GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LAYER = 0x8CD4;
enum GL_FRAMEBUFFER_COMPLETE = 0x8CD5;
enum GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT = 0x8CD6;
enum GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT = 0x8CD7;
enum GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER = 0x8CDB;
enum GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER = 0x8CDC;
enum GL_FRAMEBUFFER_UNSUPPORTED = 0x8CDD;
enum GL_MAX_COLOR_ATTACHMENTS = 0x8CDF;
enum GL_COLOR_ATTACHMENT0 = 0x8CE0;
enum GL_COLOR_ATTACHMENT1 = 0x8CE1;
enum GL_COLOR_ATTACHMENT2 = 0x8CE2;
enum GL_COLOR_ATTACHMENT3 = 0x8CE3;
enum GL_COLOR_ATTACHMENT4 = 0x8CE4;
enum GL_COLOR_ATTACHMENT5 = 0x8CE5;
enum GL_COLOR_ATTACHMENT6 = 0x8CE6;
enum GL_COLOR_ATTACHMENT7 = 0x8CE7;
enum GL_COLOR_ATTACHMENT8 = 0x8CE8;
enum GL_COLOR_ATTACHMENT9 = 0x8CE9;
enum GL_COLOR_ATTACHMENT10 = 0x8CEA;
enum GL_COLOR_ATTACHMENT11 = 0x8CEB;
enum GL_COLOR_ATTACHMENT12 = 0x8CEC;
enum GL_COLOR_ATTACHMENT13 = 0x8CED;
enum GL_COLOR_ATTACHMENT14 = 0x8CEE;
enum GL_COLOR_ATTACHMENT15 = 0x8CEF;
enum GL_DEPTH_ATTACHMENT = 0x8D00;
enum GL_STENCIL_ATTACHMENT = 0x8D20;
enum GL_FRAMEBUFFER = 0x8D40;
enum GL_RENDERBUFFER = 0x8D41;
enum GL_RENDERBUFFER_WIDTH = 0x8D42;
enum GL_RENDERBUFFER_HEIGHT = 0x8D43;
enum GL_RENDERBUFFER_INTERNAL_FORMAT = 0x8D44;
enum GL_STENCIL_INDEX1 = 0x8D46;
enum GL_STENCIL_INDEX4 = 0x8D47;
enum GL_STENCIL_INDEX8 = 0x8D48;
enum GL_STENCIL_INDEX16 = 0x8D49;
enum GL_RENDERBUFFER_RED_SIZE = 0x8D50;
enum GL_RENDERBUFFER_GREEN_SIZE = 0x8D51;
enum GL_RENDERBUFFER_BLUE_SIZE = 0x8D52;
enum GL_RENDERBUFFER_ALPHA_SIZE = 0x8D53;
enum GL_RENDERBUFFER_DEPTH_SIZE = 0x8D54;
enum GL_RENDERBUFFER_STENCIL_SIZE = 0x8D55;
enum GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE = 0x8D56;
enum GL_MAX_SAMPLES = 0x8D57;
alias GLboolean function(GLuint renderbuffer) PFNGLISRENDERBUFFERPROC;
alias void function(GLenum target, GLuint renderbuffer) PFNGLBINDRENDERBUFFERPROC;
alias void function(GLsizei n, const GLuint *renderbuffers) PFNGLDELETERENDERBUFFERSPROC;
alias void function(GLsizei n, GLuint *renderbuffers) PFNGLGENRENDERBUFFERSPROC;
alias void function(GLenum target, GLenum internalformat, GLsizei width, GLsizei height) PFNGLRENDERBUFFERSTORAGEPROC;
alias void function(GLenum target, GLenum pname, GLint *params) PFNGLGETRENDERBUFFERPARAMETERIVPROC;
alias GLboolean function(GLuint framebuffer) PFNGLISFRAMEBUFFERPROC;
alias void function(GLenum target, GLuint framebuffer) PFNGLBINDFRAMEBUFFERPROC;
alias void function(GLsizei n, const GLuint *framebuffers) PFNGLDELETEFRAMEBUFFERSPROC;
alias void function(GLsizei n, GLuint *framebuffers) PFNGLGENFRAMEBUFFERSPROC;
alias GLenum function(GLenum target) PFNGLCHECKFRAMEBUFFERSTATUSPROC;
alias void function(GLenum target, GLenum attachment, GLenum textarget, GLuint texture, GLint level) PFNGLFRAMEBUFFERTEXTURE1DPROC;
alias void function(GLenum target, GLenum attachment, GLenum textarget, GLuint texture, GLint level) PFNGLFRAMEBUFFERTEXTURE2DPROC;
alias void function(GLenum target, GLenum attachment, GLenum textarget, GLuint texture, GLint level, GLint zoffset) PFNGLFRAMEBUFFERTEXTURE3DPROC;
alias void function(GLenum target, GLenum attachment, GLenum renderbuffertarget, GLuint renderbuffer) PFNGLFRAMEBUFFERRENDERBUFFERPROC;
alias void function(GLenum target, GLenum attachment, GLenum pname, GLint *params) PFNGLGETFRAMEBUFFERATTACHMENTPARAMETERIVPROC;
alias void function(GLenum target) PFNGLGENERATEMIPMAPPROC;
alias void function(GLint srcX0, GLint srcY0, GLint srcX1, GLint srcY1, GLint dstX0, GLint dstY0, GLint dstX1, GLint dstY1, GLbitfield mask, GLenum filter) PFNGLBLITFRAMEBUFFERPROC;
alias void function(GLenum target, GLsizei samples, GLenum internalformat, GLsizei width, GLsizei height) PFNGLRENDERBUFFERSTORAGEMULTISAMPLEPROC;
alias void function(GLenum target, GLenum attachment, GLuint texture, GLint level, GLint layer) PFNGLFRAMEBUFFERTEXTURELAYERPROC;
PFNGLISRENDERBUFFERPROC glIsRenderbuffer;
PFNGLBINDRENDERBUFFERPROC glBindRenderbuffer;
PFNGLDELETERENDERBUFFERSPROC glDeleteRenderbuffers;
PFNGLGENRENDERBUFFERSPROC glGenRenderbuffers;
PFNGLRENDERBUFFERSTORAGEPROC glRenderbufferStorage;
PFNGLGETRENDERBUFFERPARAMETERIVPROC glGetRenderbufferParameteriv;
PFNGLISFRAMEBUFFERPROC glIsFramebuffer;
PFNGLBINDFRAMEBUFFERPROC glBindFramebuffer;
PFNGLDELETEFRAMEBUFFERSPROC glDeleteFramebuffers;
PFNGLGENFRAMEBUFFERSPROC glGenFramebuffers;
PFNGLCHECKFRAMEBUFFERSTATUSPROC glCheckFramebufferStatus;
PFNGLFRAMEBUFFERTEXTURE1DPROC glFramebufferTexture1D;
PFNGLFRAMEBUFFERTEXTURE2DPROC glFramebufferTexture2D;
PFNGLFRAMEBUFFERTEXTURE3DPROC glFramebufferTexture3D;
PFNGLFRAMEBUFFERRENDERBUFFERPROC glFramebufferRenderbuffer;
PFNGLGETFRAMEBUFFERATTACHMENTPARAMETERIVPROC glGetFramebufferAttachmentParameteriv;
PFNGLGENERATEMIPMAPPROC glGenerateMipmap;
PFNGLBLITFRAMEBUFFERPROC glBlitFramebuffer;
PFNGLRENDERBUFFERSTORAGEMULTISAMPLEPROC glRenderbufferStorageMultisample;
PFNGLFRAMEBUFFERTEXTURELAYERPROC glFramebufferTextureLayer;

// GL_EXT_framebuffer_multisample
bool GL_EXT_framebuffer_multisample = false;
enum GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE_EXT = 0x8D56;
enum GL_MAX_SAMPLES_EXT = 0x8D57;
enum GL_RENDERBUFFER_SAMPLES_EXT = 0x8CAB;
alias void function(GLenum target, GLsizei samples, GLenum internalformat, GLsizei width, GLsizei height) PFNGLRENDERBUFFERSTORAGEMULTISAMPLEEXTPROC;
PFNGLRENDERBUFFERSTORAGEMULTISAMPLEEXTPROC glRenderbufferStorageMultisampleEXT;
