COMPONENT=LoadFromRAMAppC

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

TINYOS_ROOT_DIR?=../../../..
include $(TINYOS_ROOT_DIR)/Makefile.include
