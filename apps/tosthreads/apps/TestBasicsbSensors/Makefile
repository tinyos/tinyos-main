COMPONENT=TestBasicsbSensorsAppC
CFLAGS += -I$(TOSDIR)/sensorboards/basicsb
CFLAGS += -I$(TOSDIR)/lib/tosthreads/sensorboards/basicsb

ifneq ($(filter mica2 micaz iris clean,$(MAKECMDGOALS)),)
  include $(MAKERULES)
else
%:
	@echo "    Sorry, this application is only written to work with mica based motes and the basicsb sensorboards.."
threads:
	@:
endif

