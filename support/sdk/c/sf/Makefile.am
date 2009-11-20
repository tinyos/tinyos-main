AUTOMAKE_OPTIONS = foreign

CFLAGS = -D_POSIX_C_SOURCE

TOS=$(shell ncc -print-tosdir)
SERIAL_H = $(TOS)/lib/serial/Serial.h

BUILT_SOURCES = serialpacket.h serialprotocol.h

bin_PROGRAMS=sf 
noinst_PROGRAMS=prettylisten sflisten sfsend seriallisten serialsend
noinst_LIBRARIES=libmote.a

sf_SOURCES = sf.c
sf_LDADD = libmote.a

prettylisten_SOURCES = prettylisten.c
prettylisten_LDADD = libmote.a

sflisten_SOURCES = sflisten.c
sflisten_LDADD = libmote.a

sfsend_SOURCES = sfsend.c
sfsend_LDADD = libmote.a

seriallisten_SOURCES = seriallisten.c
seriallisten_LDADD = libmote.a

serialsend_SOURCES = serialsend.c
serialsend_LDADD = libmote.a

libmote_a_SOURCES = \
	message.c \
	serialpacket.c \
	serialsource.c \
	sfsource.c

serialpacket.c serialpacket.h: $(SERIAL_H)
	mig -o serialpacket.h -c-prefix=spacket c $(SERIAL_H) serial_packet $(CFLAGS)

serialprotocol.h: $(SERIAL_H)
	ncg -o $@ -c-prefix=SERIAL c $(SERIAL_H) Serial.h $(CFLAGS)
