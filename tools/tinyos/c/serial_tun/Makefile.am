AUTOMAKE_OPTIONS = foreign

if !DARWIN

bin_PROGRAMS = serial_tun
serial_tun_SOURCES = serial_tun.c tun_dev.c
noinst_HEADERS = 6lowpan.h
serial_tun_LDADD = ../sf/libmote.a

AM_CFLAGS = -I../sf

endif
