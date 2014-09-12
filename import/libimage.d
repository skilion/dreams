module libimage;

extern (C) nothrow:

enum ImgError
{
	IMG_NOT_FOUND = -3,
	IMG_UNSUPPORTED = -2,
	IMG_ERROR = -1,
	IMG_NO_ERROR = 0
}

enum ImgFormat
{
	IMG_RGB = 0,
	IMG_RGBA = 1,
	IMG_ALPHA = 2
}

struct Image
{
	ImgFormat format;
	int width;
	int height;
	size_t size;
	void* data;
}

ImgError imgLoad(const char* filename, Image* image);
void imgFree(Image* image);
