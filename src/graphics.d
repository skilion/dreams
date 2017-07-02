module graphics;

import std.container;
import std.math;
import freetype;
import log;
import matrix;
import renderer;
import shaders;
import vector;

static immutable black       = Vec4f(0, 0, 0, 1);
static immutable blue        = Vec4f(0, 0, 1, 1);
static immutable green       = Vec4f(0, 1, 0, 1);
static immutable orange      = Vec4f(1, .5, 0, 1);
static immutable red         = Vec4f(1, 0, 0, 1);
static immutable transparent = Vec4f(0, 0, 0, 0);
static immutable white       = Vec4f(1, 1, 1, 1);
static immutable yellow      = Vec4f(1, 1, 0, 1);

private FT_Library ft_library;

static this()
{
	if (FT_Init_FreeType(&ft_library) != 0)
	{
		fatal("Can't initialize FreeType");
	}
}

static ~this()
{
	FT_Done_FreeType(ft_library);
}

// immediate moode drawing
final class GraphicsContext
{
	Renderer renderer;

private:
	// the drawing mode influece which shader is used
	enum DrawingMode {
		fill,
		texture,
		alphaTexture
	}
	DrawingMode drawingMode; // change this only trough setDrawingMode()

	IndexBuffer indexBuffer;
	VertexBuffer vertexBuffer;
	TextureShader textureShader;
	AlphaTexShader alphaTexShader;

	Texture texture;
	byte[4] color = [127, 127, 127, 127];

	static immutable int vertexBufferSize = 300;
	int vertexCount;
	Vertex[vertexBufferSize] vertices;

	static immutable int indexBufferSize = vertexBufferSize * 2;
	int indexCount;
	Index[indexBufferSize] indices;

	struct Rect {
		int x0, y0, x1, y1;
	}
	static immutable int maxClipRects = 64;
	int clipRectsCount;
	Rect[maxClipRects] clipRects;

public:
	this(Renderer renderer)
	{
		assert(renderer, "GraphicsContex.this: Invalid renderer");
		this.renderer = renderer;
	}

	void init()
	{
		indexBuffer = renderer.createIndexBuffer();
		vertexBuffer = renderer.createVertexBuffer();
		textureShader.init(renderer);
		alphaTexShader.init(renderer);
		clipRectsCount = 1;
		clipRects[0] = Rect(0, 0, int.max, int.max);
	}

	void shutdown()
	{
		renderer.destroyIndexBuffer(vertexBuffer);
		renderer.destroyVertexBuffer(indexBuffer);
	}

	Font createFont(string filename, int size, bool antialiasing = true)
	{
		Font font = new Font_s(renderer);
		font.create("fonts/" ~ filename, size, antialiasing);
		return font;
	}

	void destroyFont(Font font)
	{
		if (font) {
			font.destroy();
			destroy(font);
		}
	}

	void drawString(Font font, const(char)[] str, int x, int y)
	{
		translateCoord(x, y);
		setDrawingMode(DrawingMode.alphaTexture);
		dchar prevChar = 0;
		foreach (dchar c; str) {
			auto glyph = c in font.glyphs;
			if (glyph) {
				drawGlyph(glyph, x, y);
				x += glyph.advanceX + font.getKerning(prevChar, c);
			}
			prevChar = c;
		}
	}

	/*
		Returns the string width in pixels
	*/
	int getStringWidth(Font font, const(char)[] str)
	{
		return font.getStringWidth(str);
	}

	void getSize(ref int width, ref int height)
	{
		bool fullscreen;
		renderer.getDisplayMode(width, height, fullscreen);
	}

	void pushClipRect(int x, int y, int width, int height)
	{
		assert(clipRectsCount <= maxClipRects, "GraphicsContex.pushClipRect: Maximum number of clip rectangles reached");
		translateCoord(x, y);
		auto rect = Rect(x, y, x + width, y + height);
		clipRect(rect);
		clipRects[clipRectsCount++] = rect;

	}

	void popClipRect()
	{
		assert(clipRectsCount > 1, "GraphicsContex.popClipRect: Underflow");
		clipRectsCount--;
	}

	void setColor()(auto const ref Vec4f color)
	{
		this.color[0] = cast(byte) (color[0] * byte.max);
		this.color[1] = cast(byte) (color[1] * byte.max);
		this.color[2] = cast(byte) (color[2] * byte.max);
		this.color[3] = cast(byte) (color[3] * byte.max);
	}

	void setTexture(Texture texture)
	{
		if (texture != this.texture) {
			flush();
			this.texture = texture;
		}
	}

	void drawFilledRect(int x, int y, int width, int height)
	{
		translateCoord(x, y);
		auto rect = Rect(x, y, x + width, y + height);
		if (!clipRect(rect)) {
			setDrawingMode(DrawingMode.fill);
			addRect(rect, 0, 0, 0, 0);
		}
	}

	void drawTexturedRect(int x, int y, int width, int height, float s0 = 0, float t0 = 0, float s1 = 1, float t1 = 1)
	{
		translateCoord(x, y);
		auto rect = Rect(x, y, x + width, y + height);
		if (!clipRect(rect, s0, t0, s1, t1)) {
			setDrawingMode(DrawingMode.texture);
			addRect(rect, s0, t0, s1, t1);
		}
	}

	/*
		Draw a rotated rectangle centered in x, y
		The rectangle is NOT clipped
	*/
	void drawRotatedRect(int x, int y, int width, int height, float angle, float s0 = 0, float t0 = 0, float s1 = 1, float t1 = 1)
	{
		int halfWidth = width / 2;
		int halfHeight = height / 2;
		float s = sin(angle);
		float c = cos(angle);
		translateCoord(x, y);
		Vec2f t = Vec2f(x, y);
		Mat2f rotationMatrix = Mat2f(c, -s, s, c);
		Vec2f v0 = rotationMatrix * Vec2f(-halfWidth, -halfHeight) + t;
		Vec2f v1 = rotationMatrix * Vec2f(-halfWidth,  halfHeight) + t;
		Vec2f v2 = rotationMatrix * Vec2f( halfWidth,  halfHeight) + t;
		Vec2f v3 = rotationMatrix * Vec2f( halfWidth, -halfHeight) + t;
		setDrawingMode(DrawingMode.texture);
		Index i1 = addVertex(v0.x, v0.y, s0, t1);
		Index i2 = addVertex(v1.x, v1.y, s0, t0);
		Index i3 = addVertex(v2.x, v2.y, s1, t0);
		Index i4 = addVertex(v3.x, v3.y, s1, t1);
		addIndex(i1);
		addIndex(i2);
		addIndex(i3);
		addIndex(i3);
		addIndex(i4);
		addIndex(i1);
	}

	/*
		Send all cached vertices to the renderer
	*/
	void flush()
	{
		if (!indexCount) return;
		int width, height;
		getSize(width, height);
		if (width > 0 && height > 0) {
			/*
			immutable int virtualWidth = 1280;
			immutable int virtualHeight = 768;
			immutable float ratio = virtualWidth / cast(float) virtualHeight;
			float xRatio = virtualWidth / cast(float) width;
			float yRatio = virtualHeight / cast(float) height;
			float finalWidth, finalHeight;
			if (xRatio > yRatio)
			{
				finalWidth = virtualWidth;
				finalHeight = virtualHeight * height / (width / ratio);
			}
			else
			{
				finalWidth = virtualWidth * width / (height * ratio);
				finalHeight = virtualHeight;
			}
			auto mvp = orthoMatrix(0, finalWidth, 0, finalHeight, -1, 1);
			*/
			auto mvp = orthoMatrix(0, width, height, 0, -1, 1);

			renderer.updateIndexBuffer(indexBuffer, indices[0 .. indexCount], BufferUsage.streamDraw);
			renderer.updateVertexBuffer(vertexBuffer, vertices[0 .. vertexCount], BufferUsage.streamDraw);
			final switch (drawingMode)
			{
			case DrawingMode.fill:
				renderer.setShader(textureShader.shader);
				textureShader.mvp.setMat4f(mvp);
				textureShader.textureMask.setFloat(0);
				textureShader.fixedColor.setVec4f(white);
				textureShader.texture.setInteger(0);
				break;
			case DrawingMode.texture:
				renderer.setTexture(texture);
				renderer.setShader(textureShader.shader);
				textureShader.mvp.setMat4f(mvp);
				textureShader.textureMask.setFloat(1);
				textureShader.fixedColor.setVec4f(white);
				textureShader.texture.setInteger(0);
				break;
			case DrawingMode.alphaTexture:
				renderer.setTexture(texture);
				renderer.setShader(alphaTexShader.shader);
				alphaTexShader.mvp.setMat4f(mvp);
				alphaTexShader.fixedColor.setVec4f(white);
				alphaTexShader.texture.setInteger(0);
				break;
			}
			renderer.setState(0);
			renderer.draw(indexBuffer, indexCount, vertexBuffer);
		}
		indexCount = vertexCount = 0;
	}

private:
	void translateCoord(ref int x, ref int y) const
	{
		assert(clipRectsCount > 0);
		auto c = clipRects[clipRectsCount - 1];
		x += c.x0;
		y += c.y0;
	}

	void clipCoord(ref int x, ref int y) const
	{
		assert(clipRectsCount > 0);
		auto c = clipRects[clipRectsCount - 1];
		if(x < c.x0) x = c.x0;
		if(y < c.y0) y = c.y0;
		if(x > c.x1) x = c.x1;
		if(y > c.y1) y = c.y1;
	}

	/*
		Clips the given rectangle
		Returns true if the rectangle is totally clipped
	*/
	bool clipRect(ref Rect rect) const
	{
		clipCoord(rect.x0, rect.y0);
		clipCoord(rect.x1, rect.y1);
		return rect.x0 == rect.x1 || rect.y0 == rect.y1;
	}

	bool clipRect(ref Rect rect, ref float s0, ref float t0, ref float s1, ref float t1) const
	{
		Rect orect = rect;
		if (clipRect(rect)) return true;
		float cs = (s1 - s0) / (orect.x1 - orect.x0);
		float ct = (t1 - t0) / (orect.y1 - orect.y0);
		s0 += (rect.x0 - orect.x0) * cs;
		t0 += (orect.y1 - rect.y1) * ct;
		s1 += (rect.x1 - orect.x1) * cs;
		t1 += (orect.y0 - rect.y0) * ct;
		return false;
	}

	void drawGlyph(Font_s.Glyph* glyph, int x, int y)
	{
		Rect rect;
		rect.x0 = x + glyph.bearingX;
		rect.y0 = y + glyph.bearingY;
		rect.x1 = rect.x0 + glyph.width;
		rect.y1 = rect.y0 + glyph.height;
		float s0 = glyph.s0;
		float t0 = glyph.t0;
		float s1 = glyph.s1;
		float t1 = glyph.t1;
		if (!clipRect(rect, s0, t0, s1, t1)) {
			setTexture(glyph.texture);
			addRect(rect, s0, t0, s1, t1);
		}
	}

	void setDrawingMode(DrawingMode drawingMode)
	{
		if (drawingMode != this.drawingMode) {
			flush();
			this.drawingMode = drawingMode;
		}
	}

	void addRect(ref Rect rect, float s0, float t0, float s1, float t1)
	{
		if (vertexCount + 4 >= vertexBufferSize) flush();
		if (indexCount  + 6 >= indexBufferSize)  flush();
		Index i0 = addVertex(rect.x0, rect.y0, s0, t1);
		Index i1 = addVertex(rect.x0, rect.y1, s0, t0);
		Index i2 = addVertex(rect.x1, rect.y1, s1, t0);
		Index i3 = addVertex(rect.x1, rect.y0, s1, t1);
		addIndex(i0);
		addIndex(i1);
		addIndex(i2);
		addIndex(i2);
		addIndex(i3);
		addIndex(i0);
	}

	Index addVertex(T)(T x, T y, float s, float t)
	if (is (T == int) || is (T == float))
	{
		assert(vertexCount < vertexBufferSize, "GraphicsContex.addVertex: Maximum number of vertices reached");
		Index index = cast(Index) vertexCount;
		with (vertices[vertexCount++])
		{
			position[0] = x;
			position[1] = y;
			position[2] = 0;
			texcoord[0] = cast(ushort) (s * ushort.max);
			texcoord[1] = cast(ushort) (t * ushort.max);
			color[] = this.color[];
		}
		return index;
	}

	void addIndex(Index index)
	{
		assert(indexCount < indexBufferSize, "GraphicsContex.addIndex: Maximum number of indices reached");
		indices[indexCount++] = index;
	}
}

alias Font_s* Font;
private immutable int fontmapSize = 512;

private struct Font_s
{
	struct Glyph
	{
		Texture texture; // fontmap where the character is present
		float s0, t0, s1, t1;
		int width, height;
		int bearingX, bearingY;
		int advanceX;
	}

	Renderer renderer;
	string filename;
	FT_Face face;
	Glyph[dchar] glyphs;

	TextureAtlas fontmap;
	ubyte[] fontmapData; // image
	Texture currTexture; // texture representing the current fontmap

	int size; // requested size (in pixels)
	bool antialiasing;
	bool kerning;

	this(Renderer renderer)
	{
		assert(renderer);
		this.renderer = renderer;
	}

	void create(string filename, int size, bool antialiasing = true)
	{
		assert(renderer);
		this.filename = filename;
		import std.string: toStringz;
		if (FT_New_Face(ft_library, filename.toStringz(), 0, &face)) {
			fatal("Font_s.createFont: FreeType can't load the font file: %s", filename);
		}

		// select the font size
		int dpi = renderer.getDpi();
		FT_Set_Char_Size(face, size << 6, size << 6, dpi, dpi);

		this.size = size;
		this.antialiasing = antialiasing;
		kerning = FT_HAS_KERNING(face);
		fontmap.create(fontmapSize);
		fontmapData = new ubyte[fontmapSize * fontmapSize];
		currTexture = renderer.createTexture(null, fontmapSize, fontmapSize, TextureFormat.alpha, TextureFilter.bilinear, TextureWrap.clamp);
		dev("%s size is %d but height is %d", filename, size, cast(int) face.size.metrics.height >> 6);

		// preload the ascii glyphs
		foreach (dchar c; 32 .. 127) loadGlyph(c);
	}

	void destroy()
	{
		assert(renderer);
		Texture prevTexture;
		foreach (ref glyph; glyphs) {
			if (glyph.texture != prevTexture) {
				prevTexture = glyph.texture;
				renderer.destroyTexture(prevTexture);
			}
		}
		glyphs.destroy();
		fontmap.destroy();
		fontmapData.destroy();
		FT_Done_Face(face);
	}

	/*
	  Returns the string width in pixels
	*/
	int getStringWidth(const(char)[] str) const
	{
		int width = 0;
		dchar prevChar = 0;
		foreach (dchar c; str) {
			auto glyph = c in glyphs;
			if (glyph) {
				width += glyph.advanceX + getKerning(prevChar, c);
				prevChar = c;
			}
		}
		return width;
	}

	void loadGlyph(dchar c)
	{
		assert(renderer);

		// check if the glyph is already loaded
		if (c in glyphs) return;

		FT_Int32 loadFlags = FT_LOAD_RENDER | (antialiasing ? FT_LOAD_TARGET_LIGHT : FT_LOAD_TARGET_MONO);
		if (FT_Load_Char(face, c, loadFlags) != 0) {
			warning("Font_s.loadGlyph: Can't load glyph %X", c);
			glyphs[c] = Glyph();
			return;
		}

		FT_GlyphSlot slot = face.glyph;
		FT_Bitmap* bitmap = &slot.bitmap;

		// check if the character fits in the fontmap
		int x, y;
		if (!fontmap.findLocation(bitmap.width + 1, bitmap.rows + 1, x, y))
		{
			fontmap.clear();
			fontmapData[] = 0;
			currTexture = renderer.createTexture(null, fontmapSize, fontmapSize, TextureFormat.alpha, TextureFilter.bilinear, TextureWrap.clamp);
			if (!fontmap.findLocation(bitmap.width + 1, bitmap.rows + 1, x, y)) {
				warning("Font_s.loadGlyph: Glyph %X is too big to fit in the fontmap (%dx%d)", c, bitmap.width, bitmap.rows);
				glyphs[c] = Glyph();
				return;
			}
		}

		// copy the glyph in the fontmap
		ubyte* pBitmap = bitmap.buffer + (bitmap.rows - 1) * bitmap.pitch;
		ubyte* pFontmap = fontmapData.ptr + y * fontmapSize + x;
		if (antialiasing)
		{
			// 8-bit bitmap
			for (int i = 0; i < bitmap.rows; i++) {
				pFontmap[0 .. bitmap.width] = pBitmap[0 .. bitmap.width];
				pBitmap -= bitmap.pitch;
				pFontmap += fontmapSize;
			}
		}
		else
		{
			// 1-bit bitmap
			for (int i = 0; i < bitmap.rows; i++) {
				for (int j = 0; j < bitmap.width; j++) {
					int k = j >> 3; // j / 8;
					pFontmap[j] = (pBitmap[k] & 0x80) ? 0xFF : 0;
					pBitmap[k] <<= 1;
				}
				pBitmap -= bitmap.pitch;
				pFontmap += fontmapSize;
			}
		}

		// save the glyph
		const float ratio = 1.0f / fontmap.size;
		Glyph glyph = {
			texture: currTexture,
			s0: x * ratio,
			t0: y * ratio,
			s1: (x + bitmap.width) * ratio,
			t1: (y + bitmap.rows) * ratio,
			width: bitmap.width,
			height: bitmap.rows,
			bearingX: slot.bitmap_left,
			bearingY: size - slot.bitmap_top,
			advanceX: cast(int) (slot.advance.x >> 6)
		};
		glyphs[c] = glyph;

		renderer.updateTexture(currTexture, fontmapData.ptr, fontmapSize, fontmapSize, TextureFormat.alpha);
	}


	int getKerning(dchar left, dchar right) const
	{
		if (kerning) {
			FT_Vector vector;
			FT_Get_Kerning(
				face,
				FT_Get_Char_Index(face, left),
				FT_Get_Char_Index(face, right),
				FT_KERNING_DEFAULT,
				&vector
			);
			return cast(int) (vector.x >> 6);
		}
		return 0;
	}
}

/*
  Texture atlas
  Uses the skyline bottom-left algorithm to pack the sub-images
*/
private struct TextureAtlas
{
private:
	struct Node	{
		int x, y;
	}
	import std.container: Array;
	Array!(Node) skyline;

private:
	int size = 0; // size of the texture

	void create(int size)
	{
		this.size = size;
		clear();
	}

	void destroy()
	{
		size = 0;
		skyline.clear();
	}

	/*
	  Finds a location for the given rectangle
	  Returns true if the rectangle fits, false if it doesn't
	*/
	bool findLocation(int width, int height, ref int x, ref int y)
	{
		int index = -1;
		int bestX, bestY = int.max;
		int bestSpace;
		int length = cast(int) (skyline.length - 1);
		for (int i = 0; i < length; i++)
		{
			int xx, yy, space;
			if (rectangleFit(i, width, height, xx, yy, space))
			{
				if ((yy < bestY) || ((yy == bestY) && (space < bestSpace)))
				{
					index = i;
					bestX = xx;
					bestY = yy;
					bestSpace = space;
				}
			}
		}
		if (index >= 0)
		{
			updateSkyline(index, bestX, bestY, width, height);
			x = bestX;
			y = bestY;
			return true;
		}
		return false;
	}

	void clear()
	{
		skyline.clear();
		skyline.insertBack([Node(0, 0), Node(size, 0)]);
	}

private:
	/*
		Fits the given rectangle on the skyline at the given index
		Returns: true if the rectangle fits, false if it does not.
		Writes in "x" and "y" the rectangle position, and in "space" the remaining
		space between the rectangle and the next node.
	*/
	bool rectangleFit(int index, int width, int height, ref int x, out int y, ref int space)
	{
		x = skyline[index].x;
		int length = cast(int) (skyline.length - 1);
		while (index < length)
		{
			if (y < skyline[index].y)
			{
				y = skyline[index].y;
				// check if the rectangle exceed the texture size
				if (y + height >= size)	return false;
			}
			width -= skyline[index + 1].x - skyline[index].x;
			if (width <= 0)
			{
				space = -width;
				return true;
			}
			index++;
		}
		return false;
	}

	/*
		Update the skyline with the given the rectangle
	*/
	void updateSkyline(int index, int x, int y, int width, int height)
	{
		alias index start;
		int end = start + 1;
		assert(skyline[start].y <= y, "TextureAtlas.updateSkyline: The given rectangle cover the skyline");
		while (end < skyline.length)
		{
			width -= skyline[end].x - skyline[end - 1].x;
			if (width <= -4)
			{
				// a new node is needed
				skyline.insertAfter(
					skyline[0 .. end],
					Node(skyline[end].x + width, skyline[end - 1].y),
				);
				break;
			}
			else if (width <= 0)
			{
				// the rectangle ends near node
				break;
			}
			assert(skyline[end].y <= y, "TextureAtlas.updateSkyline: The given rectangle cover the skyline");
			end++;
		}
		// update the skyline height
		skyline[start] = Node(x, y + height);
		// remove the nodes covered by the rectangle
		skyline.linearRemove(skyline[++start .. end]);
	}
}
