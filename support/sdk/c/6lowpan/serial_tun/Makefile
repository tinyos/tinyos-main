#CPPFLAGS =
#LDFLAGS = 
FLAGS=
FLAGS+=-Wall
FLAGS+=-g
FLAGS+=-I${TOSROOT}/support/sdk/c

all: serial_tun

serial_tun: serial_tun.c tun_dev.c 6lowpan.h
	gcc $(FLAGS) -o serial_tun serial_tun.c tun_dev.c ${TOSROOT}/support/sdk/c/libmote.a

clean:
	rm -f serial_tun TAGS

TAGS:
	rm -f TAGS
	etags *.c *.h
