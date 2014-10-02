CC = gcc
ARCH = $(shell getconf LONG_BIT)
CFLAGS = $(CFLAGS$(ARCH)) -c -Ofast -I../libogg/include -I../libvorbis/include
CFLAGS32 = -m32 -msse2
CFLAGS64 = -m64

SOURCES = src/audio.c

OBJS = $(SOURCES:.c=.o)

.c.o:
	$(CC) $(CFLAGS) -o$@ $<

libaudio: $(OBJS)
	ar rcs lib/libaudio.a $(OBJS)

clean:
	find -name *.o -delete
	rm -f lib/libaudio.a
