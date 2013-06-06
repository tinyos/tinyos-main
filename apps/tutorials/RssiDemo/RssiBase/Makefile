COMPONENT=RssiBaseAppC

INCLUDES= -I..               \
          -I../InterceptBase

CFLAGS += $(INCLUDES)

ifneq ($(filter iris,$(MAKECMDGOALS)),) 
	CFLAGS += -DRF230_RSSI_ENERGY
endif

TINYOS_ROOT_DIR?=../../../..
include $(TINYOS_ROOT_DIR)/Makefile.include
