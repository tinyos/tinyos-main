
SOURCES=serial_tun.c tun_dev.c hashtable.c routing.c nwstate.c \
	logging.c config.c radvd-wrapper.c vty/util.c vty/vty.c \
	netlink.c mcast.c
RADVD_dir = radvd-1.0
COMMON_SRC = $(RADVD_dir)/log.c $(RADVD_dir)/socket.c $(RADVD_dir)/recv.c $(RADVD_dir)/util.c $(RADVD_dir)/radvd.h \
	$(RADVD_dir)/defaults.h $(RADVD_dir)/pathnames.h \
	$(RADVD_dir)/includes.h
RADVD_SOURCES = $(COMMON_SRC) $(RADVD_dir)/timer.c $(RADVD_dir)/send.c $(RADVD_dir)/process.c $(RADVD_dir)/interface.c \
        $(RADVD_dir)/device.c $(RADVD_dir)/device-common.c $(RADVD_dir)/gram.h 

LIBS=../lib6lowpan.a ${TOSROOT}/support/sdk/c/sf/libmote.a
TARGET=ip-driver
INCLUDE=../include/

ifndef GCC
GCC=gcc
endif

TFLAGS=-Wall -DPC -D_GNU_SOURCE  -g
TFLAGS+=-I${TOSROOT}/support/sdk/c/sf -I$(INCLUDE) -I$(RADVD_dir)/ -Ivty/

# CFLAGS+= -DCENTRALIZED_ROUTING
# CFLAGS+=-DFULL_PATH_INSTALL

ifneq ($(filter sim-null,$(MAKECMDGOALS)),)
  TFLAGS+=-DSIM
endif

ifneq ($(filter lpl,$(MAKECMDGOALS)),)
	TFLAGS+=-DBLIP_L2_RETRIES=1
endif

ifneq ($(filter sf,$(MAKECMDGOALS)),)
	TFLAGS+=-DSF_SRC
endif

sf: all
lpl: all
all: $(TARGET)
	ln -sf `pwd`/$(TARGET) ..

sim: lib
	make $(TARGET) sim-null

sim-null:
	echo Built $(TARGET) for TOSSIM

$(TARGET): $(SOURCES) $(LIBS)
	$(GCC) $(TFLAGS) $(CFLAGS) -o $(TARGET) $(SOURCES) $(RADVD_SOURCES) $(LIBS) -lm

clean:
	rm -f $(TARGET)

