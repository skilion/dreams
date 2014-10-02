#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <vorbis/vorbisfile.h>
#include "audio.h"

#pragma pack(push, 1)
typedef struct
{
	uint32_t chunkID;
	uint32_t chunkSize;
	uint32_t format;
	uint32_t subchunk1ID;
	uint32_t subchunk1Size;
	int16_t  audioFormat;
	int16_t  numChannels;
	uint32_t sampleRate;
	uint32_t byteRate;
	int16_t  blockAlign;
	int16_t  bitsPerSample;
	uint32_t subchunk2ID;
	uint32_t subchunk2Size;
} RiffWaveHeader;
#pragma pack(pop)

static int openRiffWaveStream(FILE *file, AudioStream *stream);
static int openOggVorbisStream(FILE *file, AudioStream *stream);

int openStream(const char *filename, AudioStream *stream)
{
	FILE *file = fopen(filename, "rb");
	if (!file) return ERR_FILE_NOT_FOUND;

	uint8_t header[4];
	if (fread(header, 1, sizeof(header), file) != sizeof(header)) {
		fclose(file);
		return ERR_FILE_UNSUPPORTED;
	}

	fseek(file, 0, SEEK_SET);
	if (memcmp(header, "RIFF", 4) == 0) {
		return openRiffWaveStream(file, stream);
	}
	if (memcmp(header, "OggS", 4) == 0) {
		return openOggVorbisStream(file, stream);
	}

	fclose(file);
	return ERR_FILE_UNSUPPORTED;
}

void closeStream(AudioStream *stream)
{
	switch (stream->type) {
	case TYPE_RIFF_WAVE:
		fclose(stream->data);
		break;
	case TYPE_OGG_VORBIS:
		ov_clear(stream->data);
		break;
	}
	stream->type = TYPE_INVALID;
	stream->data = NULL;
}

unsigned readStream(AudioStream *stream, char *data, unsigned size)
{
	long  total = 0;
	switch (stream->type) {
	case TYPE_RIFF_WAVE:
		return fread(data, 1, size, stream->data);
	case TYPE_OGG_VORBIS:
		while (1) {
			long read = ov_read(stream->data, data, size, 0, 2, 1, NULL);
			if (read <= 0) break;
			data += read;
			size -= read;
			total += read;
		}
		return total;
	}
	return 0;
}

unsigned getStreamPosition(AudioStream *stream)
{
	ogg_int64_t pos;
	switch (stream->type) {
	case TYPE_RIFF_WAVE:
		return (ftell(stream->data) - sizeof(RiffWaveHeader)) / (stream->bitsPerSample / 8) / stream->channels;
	case TYPE_OGG_VORBIS:
		pos = ov_pcm_tell(stream->data);
		if(pos == OV_EINVAL) return 0;
		return (unsigned) pos;
	}
	return 0;
}

int setStreamPosition(AudioStream *stream, unsigned position)
{
	switch (stream->type) {
	case TYPE_RIFF_WAVE:
		fseek(stream->data, position * (stream->bitsPerSample / 8) * stream->channels + sizeof(RiffWaveHeader), SEEK_SET);
		return 0;
	case TYPE_OGG_VORBIS:
		if (ov_pcm_seek_lap(stream->data, position) != 0) break;
		return 0;
	}
	return ERR_INVALID;
}

static int openRiffWaveStream(FILE *file, AudioStream *stream)
{
	int valid = 1;
	RiffWaveHeader header;
	size_t read = fread(&header, 1, sizeof(RiffWaveHeader), file);
	if (read != sizeof(RiffWaveHeader))   valid = 0;
	if (header.format != 0x45564157)      valid = 0; // 'WAVE'
	if (header.subchunk1ID != 0x20746D66) valid = 0; // 'fmt '
	if (header.subchunk2ID != 0x61746164) valid = 0; // 'data'
	if (header.audioFormat != 1)          valid = 0; // PCM
	if (!valid) {
		fclose(file);
		free(stream);
		return ERR_FILE_UNSUPPORTED;
	}

	stream->size = header.subchunk2Size;
	stream->bitsPerSample = header.bitsPerSample;
	stream->channels = header.numChannels;
	stream->frequency = header.sampleRate;
	stream->type = TYPE_RIFF_WAVE;
	stream->data = file;
	return 0;
}

static int openOggVorbisStream(FILE *file, AudioStream *stream)
{
	OggVorbis_File *vf;

	vf = malloc(sizeof(OggVorbis_File));
	if (ov_open_callbacks(file, vf, NULL, 0, OV_CALLBACKS_DEFAULT) != 0) {
		fclose(file);
		free(stream);
		return ERR_FILE_UNSUPPORTED;
	}

	stream->bitsPerSample = 16;
	stream->channels = ov_info(vf, -1)->channels;
	stream->size = (unsigned) ov_pcm_total(vf, -1) * 2 * stream->channels;
	stream->frequency = ov_info(vf, -1)->rate;
	stream->type = TYPE_OGG_VORBIS;
	stream->data = vf;
	return 0;
}
