TOSTHREAD_MAIN=TestLogStorage.c
THIS_SUPPORTED_PLATFORMS=tmote telos telosb eyesIFXv1 eyesIFXv2 mica2 mica2dot telosa eyesIFX micaz iris tinynode epic

ifneq ($(filter $(THIS_SUPPORTED_PLATFORMS) clean,$(MAKECMDGOALS)),)
	ifneq ($(filter tmote telos telosb eyesIFXv1,$(MAKECMDGOALS)),)
		CFLAGS+=-DUSE_STM25P
	endif
	ifneq ($(filter mica2 telosa mica2dot eyesIFX eyesIFXv2 micaz iris tinynode epic,$(MAKECMDGOALS)),)
		CFLAGS+=-DUSE_AT45DB
	endif
else
  TOSMAKE_PRE_EXE_DEPS = error
endif

error:
	@echo -e '$(ERROR_STRING) Sorry, this application is only written to work with the following platforms:'
	@echo -e '$(ERROR_STRING) $(THIS_SUPPORTED_PLATFORMS)'
	exit 1

TINYOS_ROOT_DIR?=../../../..
include $(TINYOS_ROOT_DIR)/Makefile.include
