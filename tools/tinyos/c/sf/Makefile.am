AUTOMAKE_OPTIONS = foreign

MIGFLAGS = -D_POSIX_C_SOURCE
TOS=../../../../tos
SERIAL_H = $(TOS)/lib/serial/Serial.h
TFLAGS = -I$(TOS)/types

BUILT_SOURCES = serialpacket.h serialprotocol.h

bin_PROGRAMS=sf sf-prettylisten sf-listen sf-send sf-seriallisten sf-serialsend
noinst_LIBRARIES=libmote.a

sf_SOURCES = sf.c
sf_LDADD = libmote.a

sf_prettylisten_SOURCES = prettylisten.c
sf_prettylisten_LDADD = libmote.a

sf_listen_SOURCES = sflisten.c
sf_listen_LDADD = libmote.a

sf_send_SOURCES = sfsend.c
sf_send_LDADD = libmote.a

sf_seriallisten_SOURCES = seriallisten.c
sf_seriallisten_LDADD = libmote.a

sf_serialsend_SOURCES = serialsend.c
sf_serialsend_LDADD = libmote.a

libmote_a_SOURCES = \
	message.c \
	serialpacket.c \
	serialsource.c \
	sfsource.c

serialpacket.c serialpacket.h: $(SERIAL_H)
	nescc-mig -o serialpacket.h $(TFLAGS) -c-prefix=spacket c $(SERIAL_H) serial_packet $(MIGFLAGS)

serialprotocol.h: $(SERIAL_H)
	nescc-ncg -o $@ $(TFLAGS) -c-prefix=SERIAL c $(SERIAL_H) Serial.h $(MIGFLAGS)
