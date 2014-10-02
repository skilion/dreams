We're Made of Dreams
=================

Small [demo](http://en.wikipedia.org/wiki/Demo_%28computer_programming%29) written in [D](http://dlang.org)

### Dependencies

* libaudio (custom sound file reader, included)
* [DX11](https://github.com/D-Programming-Deimos/libX11) (X11 headers for D)
* [Freetype 2](http://www.freetype.org)
* libimage (custom image reader, included)
* [libjpeg](http://www.ijg.org)
* [OggVorbis](http://xiph.org/vorbis)
* [OpenAL](http://www.openal.org)
* [libpng](http://www.libpng.org)
* [zlib](http://www.zlib.net)

### Compilation on Windows

0. Compile all dependencies (except DX11)
1. Copy all libraries in the lib folder
1. Install [Visual D](http://rainers.github.io/visuald)
2. Open the Visual Studio project

### Compilation on Linux

0. Compile DX11, libaudio, libimage
1. Copy all libraries in the lib folder
2. Install the remaining dependencies (ex. on Arch Linux run `pacman -S freetype2 libjpeg libvorbis openal libpng zlib`)
3. run `make`


### Credits

Music by [Matteo Medici](https://soundcloud.com/lnks)
