COMPONENT=AppBeaconScanningC

# CFLAGS += -DIEEE154_BEACON_TX_DISABLED
#CFLAGS += -I$(shell pwd)/..
CFLAGS += -Wall

# enable radio rx tx pins
CFLAGS += -DJN516_HWDEBUG_RADIO_RXTX_PINS

# Printf
CFLAGS += -I$(TINYOS_OS_DIR)/lib/printf
CFLAGS += -DNEW_PRINTF_SEMANTICS
CFLAGS += -DPRINTF_BUFFER_SIZE=1024

# TODO put this into a chip dependent header
CFLAGS += -DPLAIN154_TXPOWER_TOLERANCE=0x80
CFLAGS += -DPLAIN154_SUPPORTED_CHANNELS=0x07FFF800

TINYOS_ROOT_DIR?=../../../..
include $(TINYOS_ROOT_DIR)/Makefile.include

ifeq ($(findstring $(TARGET),telosb), telosb)
  CFLAGS += -D_PLATFORM_IS_TELOSB_
endif

ifeq ($(findstring $(TARGET),nxp_jn516_carrier), nxp_jn516_carrier)
  CFLAGS += -D_PLATFORM_IS_NXP_JN516_CARRIER_
endif
