TOSTHREAD_MAIN=SenseStoreAndForward.c
CFLAGS += -I$(TINYOS_OS_DIR)/lib/tosthreads/sensorboards/tmote_onboard

ifneq ($(filter telosb tmote clean,$(MAKECMDGOALS)),)
TINYOS_ROOT_DIR?=../../../..
include $(TINYOS_ROOT_DIR)/Makefile.include
else
%:
	@echo "    Sorry, this application is only written to work with telos based motes equipped with onboard sensors.."
cthreads:
	@:
dynthreads:
	@:
endif
