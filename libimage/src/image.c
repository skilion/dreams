#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <setjmp.h>
#include <jpeglib.h>
#include <png.h>
#include "image.h"

#pragma pack(push, 1)
typedef struct BmpHeader
{
	uint8_t signature[2];
	uint32_t fileSize;
	uint16_t creator1;
	uint16_t creator2;
	uint32_t offset;
} BmpHeader;

typedef struct BmpDibHeaderV3
{
	uint32_t headerSize;
	uint32_t width;
	uint32_t height;
	uint16_t planes;
	uint16_t bpp;
	uint32_t compression;
	uint32_t bmpSize;
	uint32_t hres;
	uint32_t vres;
	uint32_t nColors;
	uint32_t nImpColors;
} BmpDibHeaderV3;
#pragma pack(pop)

static ImgError imgLoadBitmap(FILE *file, Image *image);
static ImgError imgLoadPng(FILE *file, Image *image);
static ImgError imgLoadJpeg(FILE *file, Image *image);

ImgError imgLoad(const char *filename, Image *image)
{
	FILE *file = fopen(filename, "rb");
	if (!file)
	{
		return IMG_NOT_FOUND;
	}
	
	uint8_t header[8];
	fread(header, sizeof(uint8_t), 8, file);
	fseek(file, 0, SEEK_SET);
	
	ImgError error;
	if (memcmp(header, "BM", 2) == 0)
	{
		error = imgLoadBitmap(file, image);
	}
	else if (png_sig_cmp(header, 0, 8) == 0)
	{
		error = imgLoadPng(file, image);
	}
	else if (memcmp(header, "\xFF\xD8", 2) == 0)
	{
		error = imgLoadJpeg(file, image);
	}
	else
	{
		error = IMG_UNSUPPORTED;
	}
	
	fclose(file);
	return error;
}

void imgFree(Image *image)
{
	free(image->data);
	memset(image, 0, sizeof(Image));
}

static ImgError imgLoadBitmap(FILE *file, Image *image)
{
	BmpHeader bmpHeader;
	BmpDibHeaderV3 bmpDibHeader;
	fread(&bmpHeader, sizeof(BmpHeader), 1, file);
	fread(&bmpDibHeader, sizeof(BmpDibHeaderV3), 1, file);

	if (bmpDibHeader.height == 0 || bmpDibHeader.width == 0) return IMG_ERROR;
	if (bmpDibHeader.width > 4096 ||  bmpDibHeader.height > 4096) return IMG_UNSUPPORTED;
	if (bmpDibHeader.planes != 1) return IMG_UNSUPPORTED;
	if (bmpDibHeader.compression != 0) return IMG_UNSUPPORTED;
	if (bmpDibHeader.bpp != 24) return IMG_UNSUPPORTED;
	if (bmpDibHeader.width * bmpDibHeader.height * 3 != bmpDibHeader.bmpSize) return IMG_ERROR;

	image->format = IMG_RGB;
	image->width = bmpDibHeader.width;
	image->height = bmpDibHeader.height;
	image->size = bmpDibHeader.bmpSize;
	image->data = malloc(bmpDibHeader.bmpSize);
	
	fseek(file, bmpHeader.offset, SEEK_SET);
	size_t count = fread(image->data, 1, bmpDibHeader.bmpSize, file);
	if (count != bmpDibHeader.bmpSize)
	{
		free(image->data);
		return IMG_ERROR;
	}
	
	// NOTE: Pixels are stored starting from the lower left corner, going from
	//       left to right, and then row by row from the bottom to the top of the image.
	//       Each row is extended to a 32-bit (4-byte) boundary.

	//unsigned padding = rowBytes - width * 3;
	
	// BGR to RGB
	uint8_t *p = image->data;
	for (size_t i = 0; i < bmpDibHeader.bmpSize; i += 3)
	{
		char tmp = p[0];
		p[0] = p[2];
		p[2] = tmp;
		p += 3;
	}

	return IMG_NO_ERROR;
}

static void png_error_override(png_structp png_ptr, png_const_charp error_message)
{
	longjmp(png_jmpbuf(png_ptr), 1);
}

static void png_warning_override(png_structp png_ptr, png_const_charp warning_message)
{
	// nothing to do.
}

static ImgError imgLoadPng(FILE *file, Image *image)
{
	png_bytepp rowPointers = NULL;
	image->data = NULL; // it is freed in case of error

	// init the png struct
	png_structp png = png_create_read_struct(
		PNG_LIBPNG_VER_STRING,
		NULL,
		png_error_override,
		png_warning_override
	);
	if (!png) return IMG_ERROR;

	// init the info struct
	png_infop info = png_create_info_struct(png);
	if (!info)
	{
		png_destroy_read_struct(&png, NULL, NULL);
		return IMG_ERROR;
	}

	// in case of error libpng will jump here
	if (setjmp(png_jmpbuf(png)))
	{
		png_destroy_read_struct(&png, &info, NULL);
		free(image->data);
		free(rowPointers);
		return IMG_ERROR;
	}

	png_init_io(png, file);
	png_read_info(png, info);

	// try to always get a RGB or RGBA color type
	switch (png_get_color_type(png, info))
	{
	case PNG_COLOR_TYPE_GRAY:
	case PNG_COLOR_TYPE_GRAY_ALPHA:
		png_set_gray_to_rgb(png);
		break;
	case PNG_COLOR_TYPE_PALETTE:
		png_set_palette_to_rgb(png);
		break;
    }

	// strips 16 bits precision to 8 bits
	if (png_get_bit_depth(png, info) == 16)
	{
		png_set_strip_16(png);
	}

	// if the image has a trasparency set convert it to an alpha channel
	if (png_get_valid(png, info, PNG_INFO_tRNS))
	{
		png_set_tRNS_to_alpha(png);
	}

	png_read_update_info(png, info);
	switch (png_get_color_type(png, info))
	{
	case PNG_COLOR_TYPE_RGB:
		image->format = IMG_RGB;
		break;
	case PNG_COLOR_TYPE_RGB_ALPHA:
		image->format = IMG_RGBA;
		break;
	default:
		png_destroy_read_struct(&png, &info, 0);
		return IMG_UNSUPPORTED;
	}

	png_uint_32 rowSize = png_get_rowbytes(png, info);

	image->width = png_get_image_width(png, info);
	image->height = png_get_image_height(png, info);
	image->size = rowSize * image->height;
	image->data = malloc(image->size);

	// create a pointer for each row
	rowPointers = (png_bytepp) malloc(image->height * sizeof(png_bytep));
	png_bytep p = (png_bytep) image->data + rowSize * (image->height - 1);
	for (unsigned int i = 0; i < image->height; i++)
	{
		rowPointers[i] = p;
		p -= rowSize;
	}
	png_read_image(png, rowPointers);

	free(rowPointers);
	png_destroy_read_struct(&png, &info, NULL);
	return IMG_NO_ERROR;
}

typedef struct jpeg_error_mgr_override
{
	struct jpeg_error_mgr error_mgr;
	jmp_buf error_jmp;
} jpeg_error_mgr_override;

static void jpeg_error_exit_override(j_common_ptr cinfo)
{
	longjmp(((jpeg_error_mgr_override*) cinfo->err)->error_jmp, 1);
}

static void jpeg_output_message_override(j_common_ptr cinfo)
{
	// nothing to do.
}

static ImgError imgLoadJpeg(FILE *file, Image *image)
{
	struct jpeg_decompress_struct decompress;
	JSAMPARRAY rowPointers = NULL;
	image->data = NULL; // it is freed in case of error
	
	// override the default error functions
	jpeg_error_mgr_override error_mgr_override;
	decompress.err = jpeg_std_error(&error_mgr_override.error_mgr);
	decompress.err->error_exit = jpeg_error_exit_override;
	decompress.err->output_message = jpeg_output_message_override;

	// in case of error libjpeg will jump here
	if (setjmp(error_mgr_override.error_jmp))
	{
		jpeg_destroy_decompress(&decompress);
		free(rowPointers);
		free(image->data);
		return IMG_ERROR;
	}

	// init libjpeg
	jpeg_create_decompress(&decompress);
	jpeg_stdio_src(&decompress, file);
	jpeg_read_header(&decompress, TRUE);

	// init decompression
	decompress.out_color_space = JCS_RGB;
	jpeg_start_decompress(&decompress);
	if (decompress.output_components != 3)
	{
		jpeg_finish_decompress(&decompress);
		jpeg_destroy_decompress(&decompress);
		return IMG_UNSUPPORTED;
	}

	JDIMENSION rowSize = decompress.output_width * decompress.output_components;
	
	image->format = IMG_RGB;
	image->width = decompress.output_width;
	image->height = decompress.output_height;
	image->size = rowSize * decompress.output_height;
	image->data = malloc(image->size);
	
	// create a pointer for each row
	rowPointers = (JSAMPARRAY) malloc(decompress.output_height * sizeof(JSAMPROW));
	JSAMPROW p = (JSAMPROW) image->data + rowSize * (decompress.output_height - 1);
	for (JDIMENSION i = 0; i < decompress.output_height; i++)
	{
		rowPointers[i] = p;
		p -= rowSize;
	}
	
	while (decompress.output_scanline < decompress.output_height)
	{
		jpeg_read_scanlines(
			&decompress,
			rowPointers + decompress.output_scanline,
			decompress.output_height - decompress.output_scanline
		);
	}

	free(rowPointers);
	jpeg_finish_decompress(&decompress);
	jpeg_destroy_decompress(&decompress);
	return IMG_NO_ERROR;
}
