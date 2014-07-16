COMPONENT=Test_APLC

TKN154_PLATFORM_INCLUDE=$(TINYOS_OS_DIR)/platforms/telosb/mac/tkn154/Makefile.include

ifndef TKN154_MAC
PFLAGS += 	-I$(TINYOS_OS_DIR)/lib/net/zigbee/ieee802154/includes \
			-I$(TINYOS_OS_DIR)/lib/net/zigbee/ieee802154/macTDBS \
			-I$(TINYOS_OS_DIR)/lib/net/zigbee/ieee802154/phy \
			-I$(TINYOS_OS_DIR)/lib/net/zigbee/ieee802154/timerasyncTDBS \
			-I$(TINYOS_OS_DIR)/lib/net/zigbee/ieee802154/interfaces \
			-I$(TINYOS_OS_DIR)/lib/net/zigbee/ieee802154/interfaces/mac \
			-I$(TINYOS_OS_DIR)/lib/net/zigbee/ieee802154/interfaces/phy \
			-I$(TINYOS_OS_DIR)/lib/net/zigbee/cc2420 \
			-I$(TINYOS_OS_DIR)/lib/net/zigbee/ieee802154/interfaces/nwk \
			-I$(TINYOS_OS_DIR)/lib/net/zigbee/ieee802154/nwk\



else
PFLAGS += -DTKN154_MAC
PFLAGS += -I$(TINYOS_OS_DIR)/lib/mac/tkn154 \
	-I$(TINYOS_OS_DIR)/lib/mac/tkn154/dummies \
	-I$(TINYOS_OS_DIR)/lib/mac/tkn154/interfaces/MCPS \
	-I$(TINYOS_OS_DIR)/lib/mac/tkn154/interfaces/MLME \
	-I$(TINYOS_OS_DIR)/lib/mac/tkn154/interfaces/private \
	-I$(TINYOS_OS_DIR)/lib/mac/tkn154/interfaces/public\
\
-I$(TINYOS_OS_DIR)/lib/net/zigbee/wrapper\
-I$(TINYOS_OS_DIR)/lib/net/zigbee/wrapper/interfaces/mac\
-I$(TINYOS_OS_DIR)/lib/net/zigbee/wrapper/includes \
-I$(TINYOS_OS_DIR)/lib/net/zigbee/ieee802154/interfaces/nwk \
 -I$(TINYOS_OS_DIR)/lib/net/zigbee/ieee802154/nwk

  include $(TKN154_PLATFORM_INCLUDE)



endif

TINYOS_ROOT_DIR?=../../../../../..
include $(TINYOS_ROOT_DIR)/Makefile.include


