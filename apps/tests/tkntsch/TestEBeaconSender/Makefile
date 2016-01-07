COMPONENT=TestAppC

PFLAGS += -DRADIO_CHANNEL=$(TOS_CHANNEL)

# enable radio rx tx pins
CFLAGS += -DJN516_HWDEBUG_RADIO_RXTX_PINS

CFLAGS += -DPLAIN154_TXPOWER_TOLERANCE=0x80
CFLAGS += -DPLAIN154_SUPPORTED_CHANNELS=0x07FFF800

#printf
PFLAGS += -DNEW_PRINTF_SEMANTICS -DPRINTFUART_ENABLED
CFLAGS += -I$(TINYOS_OS_DIR)/lib/printf

TINYOS_ROOT_DIR?=../../../..

include $(TINYOS_ROOT_DIR)/Makefile.include

#make platform dependent ifdefs possible
include $(TINYOS_ROOT_DIR)/support/make/util/target_platform.include
