CC = gcc
CFLAGS = -c -O2
CFLAGS += -I/usr/include

SOURCES = src/audio.c

OBJS = $(SOURCES:.c=.o)

.c.o:
	$(CC) $(CFLAGS) -o$@ $<

../lib/libaudio.a: $(OBJS)
	ar rcs ../lib/libaudio.a $(OBJS)

clean:
	find -name *.o -delete
	rm -f ../lib/libaudio.a
