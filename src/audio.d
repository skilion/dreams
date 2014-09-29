module audio;

import al.al, al.alc;
import std.string: toStringz;
import cstr, log;

final class Audio
{
	private ALCdevice* device;
	private ALCcontext* context;
	private ALCint monoSourcesNum;
	private ALCint stereoSourcesNum;
	private Source[] sources;

	void init()
	{
		info("Initializing OpenAL...");

		// print all available devices
		int i = 0;
		ALchar* devices = alcGetString(null, ALC_DEVICE_SPECIFIER);
		while (*devices) {
			ALchar[] str = cstr2dstr(devices);
			info("Device %d: %s", i, str);
			devices += str.length + 1;
			i++;
		}

		device = alcOpenDevice(null);
		if (!device) {
			error("Can't open an audio device");
			return;
		}
		context = alcCreateContext(device, null);
		if (!context) {
			error("Can't create an OpenAL context");
			return;
		}
		alcMakeContextCurrent(context);
		checkErrorALC();

		info("Creating an OpenAL context on device \"%s\"", cstr2dstr(alcGetString(device, ALC_DEVICE_SPECIFIER)));
		int alcMajor, alcMinor;
		alcGetIntegerv(device, ALC_MAJOR_VERSION, 1, &alcMajor);
		alcGetIntegerv(device, ALC_MINOR_VERSION, 1, &alcMinor);
		info("OpenAL context version: %d.%d", alcMajor, alcMinor);
		// info("OpenAL context extensions: %s", cstr2dstr(alcGetString(device, ALC_EXTENSIONS)));
		alcGetIntegerv(device, ALC_MONO_SOURCES, 1, &monoSourcesNum);
		dev("OpenAL context max mono sources: %d", monoSourcesNum);
		alcGetIntegerv(device, ALC_STEREO_SOURCES, 1, &stereoSourcesNum);
		dev("OpenAL context max stereo sources: %d", stereoSourcesNum);

		info("OpenAL vendor: %s", cstr2dstr(alGetString(AL_VENDOR)));
		info("OpenAL version: %s", cstr2dstr(alGetString(AL_VERSION)));
		info("OpenAL renderer: %s", cstr2dstr(alGetString(AL_RENDERER)));
		// info("OpenAL extensions: %s", cstr2dstr(alGetString(AL_EXTENSIONS)));

		sources.length = 32;
		foreach (ref source; sources) source = new Source();
		checkErrorAL();
	}

	void shutdown()
	{
		if (!device) return;
		info("Shutting down OpenAL...");
		foreach (source; sources) destroy(source);
		alcMakeContextCurrent(null);
		alcDestroyContext(context);
		alcCloseDevice(device);
		context = null;
		device = null;
	}

	void update()
	{
		foreach (ref source; sources) {
			source.update();
		}
		checkErrorAL();
	}

	void suspend()
	{
		alcSuspendContext(context);
		alcMakeContextCurrent(null);
	}

	void resume()
	{
		alcMakeContextCurrent(context);
		alcProcessContext(context);
	}

	/*
		Returns an inactive source
	*/
	Source getSource()
	{
		foreach (source; sources) {
			if (source.isInactive()) {
				source.reset();
				return source;
			}
		}
		return null;
	}

	/*
		Straightforward function for playing sounds
	*/
	Source playSound(Sound sound)
	{
		Source source = getSource();
		source.setSound(sound);
		source.play();
		return source;
	}

	private void checkErrorALC()
	{
		ALenum errorCode = alcGetError(device);
		if (errorCode != ALC_NO_ERROR) {
			string errorString;
			switch (errorCode) {
				case ALC_INVALID_DEVICE:
					errorString = "ALC_INVALID_DEVICE";
					break;
				case ALC_INVALID_CONTEXT:
					errorString = "ALC_INVALID_CONTEXT";
					break;
				case ALC_INVALID_ENUM:
					errorString = "ALC_INVALID_ENUM";
					break;
				case ALC_INVALID_VALUE:
					errorString = "ALC_INVALID_VALUE";
					break;
				case ALC_OUT_OF_MEMORY:
					errorString = "ALC_OUT_OF_MEMORY";
					break;
				default:
					errorString = "unknow";
			}
			fatal("OpenAL context error: %s", errorString);
		}
	}
}

// TODO: should be configurable
enum queueBuffersNum = 4;

final class Source
{
	private ALuint source;
	private ALuint[queueBuffersNum] buffers;
	private Sound sound; // current source of pcm data

	private this()
	{
		alGenSources(1, &source);
		alGenBuffers(queueBuffersNum, buffers.ptr);
	}

	private ~this()
	{
		alDeleteBuffers(1, buffers.ptr);
		alDeleteSources(1, &source);
	}

	void setSound(Sound sound)
	{
		assert(sound);
		this.sound = sound;
		if (sound.isStreamed) {
			sound.seekPcm(0);
			initBuffers();
		} else {
			alBufferData(buffers[0], sound.format, sound.buffer.ptr, cast(ALsizei) sound.buffer.length, sound.frequency);
			alSourcei(source, AL_BUFFER, buffers[0]);
		}
	}

	void setGain(float gain)
	{
		alSourcef(source, AL_GAIN, gain);
	}

	void setPosition(float[3] position)
	{
		alSourcefv(source, AL_POSITION, position.ptr);
	}

	/*
		Reset all attributes to their default value
		Can be called only if the sound is inactive
	*/
	void reset()
	{
		alSource3f(source, AL_POSITION, 0, 0, 0);
		alSourcei(source, AL_LOOPING, AL_FALSE);
		alSourcef(source, AL_GAIN, 1.0f);
		alSourcei(source, AL_BUFFER, AL_NONE);
	}

	void play()
	{
		alSourcePlay(source);
	}

	void pause()
	{
		alSourcePause(source);
	}

	void stop()
	{
		alSourceStop(source);
		if (sound.isStreamed) sound.seekPcm(0);
	}

	bool isActive()
	{
		ALint state;
		alGetSourcei(source, AL_SOURCE_STATE, &state);
		return state == AL_PLAYING || state == AL_PAUSED;
	}

	bool isInactive()
	{
		ALint state;
		alGetSourcei(source, AL_SOURCE_STATE, &state);
		return state == AL_INITIAL || state == AL_STOPPED;
	}

	/*void seekPcm(uint position)
	{
		if (isStreamed) {
			setStreamPosition(&stream, position);
		} else {
			alSourcei(source, AL_SAMPLE_OFFSET, position);
		}
	}

	uint tellPcm()
	{
		uint position;
		alGetSourcei(source, AL_SAMPLE_OFFSET, &position);
		if (isStreamed) {
			assert(0);
			//position += getStreamPosition(&stream);
		}
		return position;
	}*/

	void seekTime(float position)
	{
		assert(isInactive(), "Source.seekTime: Source is playing");
		if (sound.isStreamed) {
			sound.seekTime(position);
			alSourcei(source, AL_BUFFER, AL_NONE);
			initBuffers();
		} else {
			alSourcef(source, AL_SEC_OFFSET, position);
		}
	}

	/*float tellTime()
	{
		float position;
		if (isStreamed) {
		} else {
			alGetSourcef(source, AL_SEC_OFFSET, &position);
		}
		return position;
	}*/

	void update()
	{
		if (sound && sound.isStreamed) {
			ALint processed;
			alGetSourcei(source, AL_BUFFERS_PROCESSED, &processed);
			while(processed--) {
				ALuint buffer;
				alSourceUnqueueBuffers(source, 1, &buffer);
				if (fillBuffer(buffer)) {
					alSourceQueueBuffers(source, 1, &buffer);
				}
				// TODO: looping music stream
			}
			// prevent the source from stopping
			ALint state, queued;
			alGetSourcei(source, AL_SOURCE_STATE, &state);
			alGetSourcei(source, AL_BUFFERS_QUEUED, &queued);
			if (state == AL_STOPPED && queued > 0) alSourcePlay(source);
		}
	}

	private bool fillBuffer(ALuint buffer)
	{
		ALsizei read = sound.fillBuffer();
		alBufferData(buffer, sound.format, sound.buffer.ptr, read, sound.frequency);
		return read != 0;
	}

	private void initBuffers()
	{
		foreach (buffer; buffers) fillBuffer(buffer);
		alSourceQueueBuffers(source, queueBuffersNum, buffers.ptr);
	}
}

/*final class SourceGroup
{
	Source getSource();
	void play(Sound sound);
	void stop();
	void pause();
	void setGain();
	void setPosition(const float[3] position);
	void setVelocity(const float[3] velocity);
	void setOrientation(const float[3] forward, const float[3] up);
}*/

private void checkErrorAL()
{
	ALenum errorCode = alGetError();
	if (errorCode != AL_NO_ERROR) {
		string errorString;
		switch (errorCode) {
			case AL_INVALID_NAME:
				errorString ="AL_INVALID_NAME";
				break;
			case AL_INVALID_ENUM:
				errorString = "AL_INVALID_ENUM";
				break;
			case AL_INVALID_VALUE:
				errorString = "AL_INVALID_VALUE";
				break;
			case AL_INVALID_OPERATION:
				errorString = "AL_INVALID_OPERATION";
				break;
			case AL_OUT_OF_MEMORY:
				errorString = "AL_OUT_OF_MEMORY";
				break;
			default:
				errorString = "unknow";
		}
		fatal("OpenAL error: %s", errorString);
	}
}

// TODO: should be configurable
enum streamBufferSize = 32 * 1024; // 32 KiB

final class Sound
{
	ALenum format;
	ALsizei frequency;
	AudioStream stream;
	byte[] buffer; // if isStreamed == false the sound is all here
	bool isStreamed;

	this(const(char)[] filename, bool isStreamed)
	{
		load(filename, isStreamed);
	}

	~this()
	{
		close();
	}

	void load(const(char)[] filename, bool isStreamed)
	{
		this.isStreamed = isStreamed;
		int result = openStream(toStringz("sounds/" ~ filename), &stream);
		if (result == Error.ERR_FILE_NOT_FOUND) {
			fatal("Couldn't load the sound file: %s", filename);
		}
		if (result == Error.ERR_FILE_UNSUPPORTED) {
			fatal("Unsupported sound file: %s", filename);
		}
		if (result == Error.ERR_INVALID) {
			fatal("Invalid sound file: %s", filename);
		}
		frequency = stream.frequency;
		switch(stream.bitsPerSample) {
		case 8:
			switch(stream.channels) {
			case 1:
				format = AL_FORMAT_MONO8;
				break;
			case 2:
				format = AL_FORMAT_STEREO8;
				break;
			default:
				fatal("Unsupported number of channels: %d (%s)", stream.channels, filename);
			}
			break;
		case 16:
			switch(stream.channels) {
			case 1:
				format = AL_FORMAT_MONO16;
				break;
			case 2:
				format = AL_FORMAT_STEREO16;
				break;
			default:
				fatal("Unsupported number of channels: %d (%s)", stream.channels, filename);
			}
			break;
		default:
			fatal("Unsupported number of bits per sample: %d (%s)", stream.bitsPerSample, filename);
		}
		if (isStreamed) {
			// preload the sound
			buffer.length = streamBufferSize;
			fillBuffer();
		} else {
			// load the complete sound in memory
			buffer.length = stream.size;
			uint size = fillBuffer();
			close(); // close the stream
			if (size != stream.size) {
				fatal("Sound size mismatch: %s", filename);
			}
		}
	}

	void close()
	{
		closeStream(&stream);
	}

	uint read(byte[] data, uint size)
	{
		return readStream(&stream, data.ptr, size);
	}

	/*
		Fill the buffer with data from the sound file
	*/
	uint fillBuffer()
	{
		return read(buffer, cast(uint) buffer.length);
	}

	void seekPcm(uint position)
	{
		setStreamPosition(&stream, position);
	}

	uint tellPcm()
	{
		return getStreamPosition(&stream);
	}

	void seekTime(float position)
	{
		setStreamPosition(&stream, cast(uint) (position * frequency));
	}

	float tellTime()
	{
		return getStreamPosition(&stream) / cast(float) frequency;
	}
}

private:

enum Error {
	ERR_FILE_NOT_FOUND = -3,
	ERR_FILE_UNSUPPORTED = -2,
	ERR_INVALID = -1
};

struct AudioStream {
	uint size; // total size of the uncompressed sound in bytes
	uint bitsPerSample;
	uint channels;
	uint frequency;
	int type;
	void* data;
}

extern (C):

int openStream(const char* filename, AudioStream* stream);
void closeStream(AudioStream* stream);
uint readStream(AudioStream* stream, byte* data, uint size);
uint getStreamPosition(AudioStream* stream);
int setStreamPosition(AudioStream* stream, uint position);
