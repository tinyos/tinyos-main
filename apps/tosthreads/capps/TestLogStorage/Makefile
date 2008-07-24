TOSTHREAD_MAIN=TestLogStorage.c
THIS_SUPPORTED_PLATFORMS=tmote telos telosb eyesIFXv1 eyesIFXv2 mica2 mica2dot telosa eyesIFX micaz iris tinynode

ifneq ($(filter $(THIS_SUPPORTED_PLATFORMS) clean,$(MAKECMDGOALS)),)
        ifneq ($(filter tmote telos telosb eyesIFXv1,$(MAKECMDGOALS)),)
                CFLAGS+=-DUSE_STM25P
        endif
        ifneq ($(filter mica2 telosa mica2dot eyesIFX eyesIFXv2 micaz iris tinynode,$(MAKECMDGOALS)),)
                CFLAGS+=-DUSE_AT45DB
        endif

        include $(MAKERULES)
else
%:
	@echo "    Sorry, this application is only written to work with the following platforms:"
	@echo "        $(THIS_SUPPORTED_PLATFORMS)"
cthreads:
	@:
endif
