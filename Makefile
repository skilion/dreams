DFLAGS = -odbin -ofbin/dreams
DFLAGS += -Iimport -Iext/libDX11/import
DFLAGS += -L-Llib -L-Lext/libDX11/lib
DFLAGS += -L-laudio -L-ldl -L-lDX11-dmd -L-lfreetype -L-limage -L-ljpeg -L-lvorbis -L-lvorbisfile -L-logg -L-lopenal -L-lpng -L-lX11

SOURCES = \
	src/dreams/camera.d \
	src/dreams/culling.d \
	src/dreams/demo.d \
	src/dreams/editor.d \
	src/dreams/entities.d \
	src/dreams/effects.d \
	src/dreams/imm3d.d \
	src/dreams/noise.d \
	src/dreams/particles.d \
	src/dreams/skybox.d \
	src/dreams/view.d \
	src/dreams/world.d \
	src/dreams/world_mesh.d \
	src/dreams/world_renderer.d \
	src/gl/common.d \
	src/gl/core.d \
	src/gl/ext.d \
	src/linux/glloader.d \
	src/linux/glwindow.d \
	src/linux/glx.d \
	src/linux/glxext.d \
	src/linux/init.d \
	src/linux/keysym.d \
	src/audio.d \
	src/cstr.d \
	src/engine.d \
	src/graphics.d \
	src/input.d \
	src/log.d \
	src/main.d \
	src/matrix.d \
	src/mesh.d \
	src/renderer.d \
	src/shaders.d \
	src/signals.d \
	src/vector.d \
	src/zfile.d

bin/dreams: $(SOURCES) ext/libDX11/lib/libDX11-dmd.a lib/libaudio.a lib/libimage.a
	dmd -O -release -inline $(DFLAGS) $(SOURCES)

debug: DFLAGS += -g -gx
debug: bin/dreams

ext/libDX11/lib/libDX11-dmd.a:
	cd ext/libDX11 && $(MAKE) DC=dmd

lib/libaudio.a:
	cd libaudio && $(MAKE)

lib/libimage.a:
	cd libimage&& $(MAKE)
clean:
	cd ext/libDX11 && $(MAKE) clean
	cd libaudio && $(MAKE) clean
	cd libimage&& $(MAKE) clean
	rm -f bin/dreams.o bin/dreams
