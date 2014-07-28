COMPONENT=SerialLoaderAppC

GOALS += threads

THREADS_DIR ?= $(TINYOS_OS_DIR)/lib/tosthreads
CFLAGS += -I$(THREADS_DIR)/lib/tinyld
CFLAGS += -I$(THREADS_DIR)/csystem
CFLAGS += -I$(THREADS_DIR)/sensorboards/tmote_onboard
CFLAGS += -I$(THREADS_DIR)/sensorboards/universal
CFLAGS += -I$(THREADS_DIR)/lib/net/ctp
CFLAGS += -I$(THREADS_DIR)/lib/net
CFLAGS += -I$(TINYOS_OS_DIR)/lib/net
CFLAGS += -I$(TINYOS_OS_DIR)/lib/net/ctp
CFLAGS += -I$(TINYOS_OS_DIR)/lib/net/4bitle
CFLAGS += -I$(THREADS_DIR)/lib/printf

ifdef TENET
    CFLAGS += -DTOSTHREAD_TENET=1
endif
CFLAGS += -DDISABLE_LOADER_FLASH=1
CFLAGS += -DDISABLE_LOADER_USERBUTTON=1

TOSMAKE_CLEAN_EXTRA += *.pyc

TINYOS_ROOT_DIR?=../../../..
include $(TINYOS_ROOT_DIR)/Makefile.include
