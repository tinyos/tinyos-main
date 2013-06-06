COMPONENT=coordinatorBasicAppC
PLATFORMS = telosb

ZIGBEE=$(TINYOS_OS_DIR)/lib/zigbee/clusterTree

# Shadows new version of files w.r.t. the official ones (if needed)
PFLAGS += 	-I$(ZIGBEE)/../shadow

PFLAGS += 	-I$(ZIGBEE)/includes	\
			-I$(ZIGBEE)/interfaces	\
			-I$(ZIGBEE)/nwk


PFLAGS += -DIM_COORDINATOR

ifdef DEF_MAC_PANID
PFLAGS += -DDEF_MAC_PANID=$(DEF_MAC_PANID)
endif

ifdef DEF_CHANNEL
PFLAGS += -DDEF_CHANNEL=$(DEF_CHANNEL)
endif

ifdef BUILDDIR
PFLAGS += -DCBUILDDIR=$(BUILDDIR)
endif

ifdef DEF_DEVICE_DEPTH
PFLAGS += -DDEF_DEVICE_DEPTH=$(DEF_DEVICE_DEPTH)
endif

ifdef DEF_CHOSEN_PARENT
PFLAGS += -DDEF_CHOSEN_PARENT=$(DEF_CHOSEN_PARENT)
endif

ifdef DEF_MY_X
PFLAGS += -DDEF_MY_X=$(DEF_MY_X)
endif

ifdef DEF_MY_Y
PFLAGS += -DDEF_MY_Y=$(DEF_MY_Y)
endif


ifdef IEEE154_EXTENDED_ADDRESS
PFLAGS += -DIEEE154_EXTENDED_ADDRESS=$(IEEE154_EXTENDED_ADDRESS)
endif

ifdef TKN154_DEBUG
PFLAGS += -DTKN154_DEBUG
CFLAGS += -I$(TINYOS_OS_DIR)/lib/printf
PFLAGS += -DPRINTF_BUFFER_SIZE=1000
endif

# Try to optimize memory allocation by disabling some MAC services
#CFLAGS += -DIEEE154_RXENABLE_DISABLED -DIEEE154_DISASSOCIATION_DISABLED
#CFLAGS += -DIEEE154_RXENABLE_DISABLED -DIEEE154_DISASSOCIATION_DISABLED -DIEEE154_COORD_REALIGNMENT_DISABLED
#CFLAGS += -DIEEE154_RXENABLE_DISABLED

CFLAGS += -DTKN154_ACTIVE_MESSAGE_SUPPORT_DISABLED -DIEEE154_PROMISCUOUS_MODE_DISABLED -DIEEE154_GTS_DISABLED


# To use the TKN15.4 MAC instead of a platform's default MAC protocol first
# include the TinyOS "Makerules" file as usual ...
TINYOS_ROOT_DIR?=../../../../..
include $(TINYOS_ROOT_DIR)/Makefile.include
# ... and then include the TKN15.4 "Makefile.include" file. That's all.
# Hint: type "make <platform> verbose" to see the aggregate include path.
include $(TINYOS_OS_DIR)/lib/mac/tkn154/Makefile.include

