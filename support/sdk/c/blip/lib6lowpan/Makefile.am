
AM_CFLAGS = -DPC
noinst_LIBRARIES = lib6lowpan.a

noinst_lib6lowpandir = $(includedir)/lib6lowpan-2.1.1
noinst_lib6lowpan_HEADERS = 6lowpan.h  devconf.h  IEEE154Packet.h  in_cksum.h  \
	ip.h  ip_malloc.h  lib6lowpan.h  TrackFlows.h
lib6lowpan_a_SOURCES = lib6lowpan.c lib6lowpanIP.c lib6lowpanFrag.c $(lib6lowpan_HEADERS)

