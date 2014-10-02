CC = gcc
ARCH = $(shell getconf LONG_BIT)
CFLAGS = $(CFLAGS$(ARCH)) -c -Ofast -std=c99 -I../libjpeg/src -I../libpng/src
CFLAGS32 = -m32 -msse2
CFLAGS64 = -m64

SOURCES = src/image.c

OBJS = $(SOURCES:.c=.o)

.c.o:
	$(CC) $(CFLAGS) -o$@ $<

libimage: $(OBJS)
	ar rcs lib/libimage.a $(OBJS)

clean:
	find -name *.o -delete
	rm -f lib/libimage.a
