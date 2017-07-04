CC = gcc
CFLAGS = -c -O2
CFLAGS += -I/usr/include

SOURCES = src/image.c

OBJS = $(SOURCES:.c=.o)

.c.o:
	$(CC) $(CFLAGS) -o$@ $<

../lib/libimage.a: $(OBJS)
	ar rcs ../lib/libimage.a $(OBJS)

clean:
	find -name *.o -delete
	rm -f ../lib/libimage.a
