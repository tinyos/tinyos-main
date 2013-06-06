TOSTHREAD_MAIN=TestCollection.c

CFLAGS += -I$(TINYOS_OS_DIR)/lib/tosthreads/sensorboards/universal

CFLAGS += -I$(TINYOS_OS_DIR)/lib/tosthreads/lib/net/
CFLAGS += -I$(TINYOS_OS_DIR)/lib/net/

CFLAGS += -I$(TINYOS_OS_DIR)/lib/tosthreads/lib/net/ctp
CFLAGS += -I$(TINYOS_OS_DIR)/lib/net/ctp  -I$(TINYOS_OS_DIR)/lib/net/4bitle

ifneq ($(filter telosb tmote tinynode shimmer shimmer2 shimmer2r span iris epic clean,$(MAKECMDGOALS)),) 
TINYOS_ROOT_DIR?=../../../..
include $(TINYOS_ROOT_DIR)/Makefile.include
else
%:
	@echo "    Sorry, this application only works on platforms with >8kB of RAM (telos, iris, etc.)"
cthreads:
	@:
dynthreads:
	@:
endif

