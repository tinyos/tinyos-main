
AM_CFLAGS = -DPC -I../../../../../tos/types -I../../sf

sbin_PROGRAMS = ieee154-interface

ieee154_interface_SOURCES = ieee154-interface.c tun_dev.c \
	tun_dev.h logging.c device-config.h config.c queue.c

LDADD = ../lib6lowpan/lib6lowpan.a ../../sf/libmote.a -lpthread
