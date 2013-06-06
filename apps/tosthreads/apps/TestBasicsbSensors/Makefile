COMPONENT=TestBasicsbSensorsAppC
CFLAGS += -I$(TINYOS_OS_DIR)/sensorboards/basicsb
CFLAGS += -I$(TINYOS_OS_DIR)/lib/tosthreads/sensorboards/basicsb

ifneq ($(filter mica2 mica2dot micaz iris clean,$(MAKECMDGOALS)),)
TINYOS_ROOT_DIR?=../../../..
include $(TINYOS_ROOT_DIR)/Makefile.include
else
%:
	@echo "    Sorry, this application is only written to work with mica based motes and the basicsb sensorboards.."
threads:
	@:
endif

