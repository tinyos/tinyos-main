
SUBDIRS = . trace tests

AM_CFLAGS = -DPC -I../../../../../tos/types -I../../../.. -DHAVE_LOWPAN_EXTERN_MATCH_CONTEXT
noinst_LIBRARIES = lib6lowpan.a

noinst_lib6lowpandir = $(includedir)/lib6lowpan-2.2.0
noinst_HEADERS = 6lowpan.h in_cksum.h ip.h ip_malloc.h lib6lowpan.h nwbyte.h
lib6lowpan_a_SOURCES = lib6lowpan.c lib6lowpan_4944.c lib6lowpan_frag.c \
	iovec.c utility.c in_cksum.c ieee154_header.c ip_malloc.c $(lib6lowpan_HEADERS)
