TOSTHREAD_MAIN=SenseStoreAndForward.c
CFLAGS += -I$(TOSDIR)/lib/tosthreads/sensorboards/tmote_onboard

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
