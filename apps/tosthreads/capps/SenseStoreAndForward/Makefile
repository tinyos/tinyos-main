TOSTHREAD_MAIN=SenseStoreAndForward.c
CFLAGS += -I$(TINYOS_OS_DIR)/lib/tosthreads/sensorboards/tmote_onboard

ifeq ($(filter telosb tmote epic clean,$(MAKECMDGOALS)),)
TOSMAKE_PRE_EXE_DEPS = error
endif

error:
	@echo -e '$(ERROR_STRING) Sorry, this application is only written to work with telos based motes equipped with onboard sensors.'
	exit 1

TINYOS_ROOT_DIR?=../../../..
include $(TINYOS_ROOT_DIR)/Makefile.include
