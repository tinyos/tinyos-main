TOSTHREAD_MAIN=TestCollection.c

CFLAGS += -I$(TINYOS_OS_DIR)/lib/tosthreads/sensorboards/universal

CFLAGS += -I$(TINYOS_OS_DIR)/lib/tosthreads/lib/net/
CFLAGS += -I$(TINYOS_OS_DIR)/lib/net/

CFLAGS += -I$(TINYOS_OS_DIR)/lib/tosthreads/lib/net/ctp
CFLAGS += -I$(TINYOS_OS_DIR)/lib/net/ctp  -I$(TINYOS_OS_DIR)/lib/net/4bitle

ifeq ($(filter telosb tmote tinynode shimmer shimmer2 shimmer2r span iris epic clean,$(MAKECMDGOALS)),)
TOSMAKE_PRE_EXE_DEPS = error
endif

error:
	@echo -e '$(ERROR_STRING) Sorry, this application only works on platforms with >8kB of RAM (telos, iris, etc.)'
	exit 1

TINYOS_ROOT_DIR?=../../../..
include $(TINYOS_ROOT_DIR)/Makefile.include
