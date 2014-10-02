DC = dmd
DFLAGS = -od./bin -of./bin/$@ -I./import -L-L./lib -L-laudio -L-ldl \
	-L-lDX11-dmd -L-lfreetype -L-limage -L-ljpeg -L-lvorbis -L-lvorbisfile \
	-L-logg -L-lopenal -L-lpng -L-lX11  -L-lz
#DFLAGS += -debug -g
DFLAGS += -boundscheck=off -inline -O -release

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

dreams: $(SOURCES)
	$(DC) $(DFLAGS) $(SOURCES)

clean:
	cd bin; \
	rm -f app *.o
