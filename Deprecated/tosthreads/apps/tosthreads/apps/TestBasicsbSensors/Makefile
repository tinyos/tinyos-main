COMPONENT=TestBasicsbSensorsAppC

ifeq ($(filter mica2 mica2dot micaz iris clean,$(MAKECMDGOALS)),)
$(error $(shell echo -e 'ERROR: Sorry, this application is only written to work with mica based motes and the basicsb sensorboards'))
endif

TINYOS_ROOT_DIR?=../../../..
include $(TINYOS_ROOT_DIR)/Makefile.include
$(call TOSMake_include_sensor,basicsb)
