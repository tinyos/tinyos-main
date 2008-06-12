TOSTHREAD_MAIN=ReceiveStoreDecompress.c
CFLAGS += -I..

ifneq ($(filter telosb tmote clean,$(MAKECMDGOALS)),)
  include $(MAKERULES)
else
%:
	@echo "    Sorry, this application is only written to work with telos based motes equipped with onboard sensors.."
cthreads:
	@:
dynthreads:
	@:
endif
