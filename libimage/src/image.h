typedef enum ImgError
{
	IMG_NOT_FOUND = -3,
	IMG_UNSUPPORTED = -2,
	IMG_ERROR = -1,
	IMG_NO_ERROR = 0
} ImgError;

typedef enum ImgFormat
{
	IMG_RGB = 0,
	IMG_RGBA = 1,
	IMG_ALPHA = 2	
} ImgFormat;

typedef struct Image
{
	ImgFormat format;
	unsigned int width;
	unsigned int height;
	size_t size;
	void *data; // stored from the bottom-left corner to the top-right
} Image;

ImgError imgLoad(const char *filename, Image *image);
void imgFree(Image *image);
