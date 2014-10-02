enum Error {
	ERR_FILE_NOT_FOUND = -3,
	ERR_FILE_UNSUPPORTED = -2,
	ERR_INVALID = -1
};

enum Type {
	TYPE_INVALID,
	TYPE_RIFF_WAVE,
	TYPE_OGG_VORBIS
};

typedef struct {
	unsigned size; // total size of the uncompressed sound in bytes
	unsigned bitsPerSample;
	unsigned channels;
	unsigned frequency;
	int type;
	void *data;
} AudioStream;

int openStream(const char *filename, AudioStream *stream);
void closeStream(AudioStream *stream);
unsigned readStream(AudioStream *stream, char *data, unsigned size);
unsigned getStreamPosition(AudioStream *stream);
int setStreamPosition(AudioStream *stream, unsigned position);
