COMPONENT=TestAppC

CFLAGS += -DJN516_SNIFFER_CHANNEL=$(TOS_CHANNEL)

#nxp micro mac import
APPLIBS += MMAC
INCFLAGS += -I$(COMPONENTS_BASE_DIR)/MAC/Include 

TINYOS_ROOT_DIR?=../../../..
include $(TINYOS_ROOT_DIR)/Makefile.include

