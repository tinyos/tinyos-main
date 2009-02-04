COMPONENT=SerialLoaderAppC

GOALS += threads

THREADS_DIR ?= $(TOSDIR)/lib/tosthreads
CFLAGS += -I$(THREADS_DIR)/lib/tinyld
CFLAGS += -I$(THREADS_DIR)/csystem
CFLAGS += -I$(THREADS_DIR)/sensorboards/tmote_onboard
CFLAGS += -I$(THREADS_DIR)/sensorboards/universal
CFLAGS += -I$(THREADS_DIR)/lib/net/ctp
CFLAGS += -I$(THREADS_DIR)/lib/net
CFLAGS += -I$(TOSDIR)/lib/net
CFLAGS += -I$(TOSDIR)/lib/net/ctp
CFLAGS += -I$(TOSDIR)/lib/net/4bitle
CFLAGS += -I$(THREADS_DIR)/lib/printf

ifdef TENET
    CFLAGS += -DTOSTHREAD_TENET=1
endif
CFLAGS += -DDISABLE_LOADER_FLASH=1
CFLAGS += -DDISABLE_LOADER_USERBUTTON=1

CLEAN_EXTRA += *.pyc

include $(MAKERULES)
