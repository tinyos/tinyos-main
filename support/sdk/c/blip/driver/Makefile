
SOURCES=serial_tun.c tun_dev.c hashtable.c routing.c nwstate.c \
	logging.c config.c radvd-wrapper.c

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

TFLAGS=-Wall -g -DPC
TFLAGS+=-I${TOSROOT}/support/sdk/c/sf -I$(INCLUDE) -Iradvd/


ifneq ($(filter sim-null,$(MAKECMDGOALS)),)
  TFLAGS+=-DSIM
endif

# CFLAGS+=-DFULL_PATH_INSTALL
all: $(TARGET)

sim: lib
	make $(TARGET) sim-null

sim-null:
	echo Built $(TARGET) for TOSSIM

$(TARGET): $(SOURCES) $(LIBS)
	$(GCC) $(TFLAGS) $(CFLAGS) -o $(TARGET) $(SOURCES) $(radvd_SOURCES) $(LIBS) -lm

clean:
	rm $(TARGET)

