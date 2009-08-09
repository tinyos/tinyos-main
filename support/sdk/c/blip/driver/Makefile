
SOURCES=serial_tun.c tun_dev.c hashtable.c routing.c nwstate.c \
	logging.c config.c radvd-wrapper.c vty/util.c vty/vty.c \
	netlink.c mcast.c

COMMON_SRC = radvd/log.c radvd/socket.c radvd/recv.c radvd/util.c radvd/radvd.h \
	radvd/defaults.h radvd/pathnames.h \
        radvd/includes.h
radvd_SOURCES = $(COMMON_SRC) radvd/timer.c radvd/send.c radvd/process.c radvd/interface.c \
        radvd/device.c radvd/device-common.c radvd/gram.h 

LIBS=../lib6lowpan.a ${TOSROOT}/support/sdk/c/sf/libmote.a
TARGET=ip-driver
INCLUDE=../include/

ifndef GCC
GCC=gcc
endif

TFLAGS=-Wall -DPC -D_GNU_SOURCE  -g
TFLAGS+=-I${TOSROOT}/support/sdk/c/sf -I$(INCLUDE) -Iradvd/ -Ivty/

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
	$(GCC) $(TFLAGS) $(CFLAGS) -o $(TARGET) $(SOURCES) $(radvd_SOURCES) $(LIBS) -lm

clean:
	rm -f $(TARGET)

