
# SUBDIRS = radvd-1.0

sbin_PROGRAMS = ip-driver

radvddir = radvd-1.0
ip_driver_SOURCES=serial_tun.c tun_dev.c hashtable.c routing.c nwstate.c \
	logging.c config.c radvd-wrapper.c  vty/vty.c vty/vty-util.c vty/vty.h \
	netlink.c mcast.c \
  $(radvddir)/log.c $(radvddir)/socket.c $(radvddir)/recv.c $(radvddir)/util.c $(radvddir)/radvd.h \
	$(radvddir)/defaults.h $(radvddir)/pathnames.h \
	$(radvddir)/includes.h \
  $(radvddir)/timer.c $(radvddir)/send.c $(radvddir)/process.c $(radvddir)/interface.c \
  $(radvddir)/device.c $(radvddir)/device-common.c $(radvddir)/gram.h \
	config.h  hashtable.h  hashtable_private.h  \
	logging.h  mcast.h  netlink.h  nwstate.h  \
	routing.h  tun_dev.h	
ip_driver_CFLAGS = -DPC -D_GNU_SOURCE -I$(TOSROOT)/support/sdk/c/sf/ -I..
LDADD = ../lib6lowpan/lib6lowpan.a $(TOSROOT)/support/sdk/c/sf/libmote.a
