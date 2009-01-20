
SOURCES=serial_tun.c tun_dev.c hashtable.c routing.c nwstate.c \
	logging.c config.c radvd-wrapper.c

RADVD=./radvd-1.0
COMMON_SRC = $(RADVD)/log.c $(RADVD)/socket.c $(RADVD)/recv.c $(RADVD)/util.c $(RADVD)/radvd.h \
	$(RADVD)/defaults.h $(RADVD)/pathnames.h \
        $(RADVD)/includes.h
radvd_SOURCES = $(COMMON_SRC) $(RADVD)/timer.c $(RADVD)/send.c $(RADVD)/process.c $(RADVD)/interface.c \
        $(RADVD)/device.c $(RADVD)/device-common.c $(RADVD)/gram.h 

LIBS=../lib6lowpan.a ${TOSROOT}/support/sdk/c/sf/libmote.a 
TARGET=ip-driver
INCLUDE=../include/

ifndef GCC
GCC=gcc
endif

TFLAGS=-Wall -g -DPC
TFLAGS+=-I${TOSROOT}/support/sdk/c/sf -I$(INCLUDE) -I$(RADVD)/


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

