COMPONENT=Test_APL

TKN154_PLATFORM_INCLUDE=$(TOSROOT)/tos/platforms/telosb/mac/tkn154/Makefile.include

ifndef TKN154_MAC
PFLAGS += 	-I$(TOSROOT)/tos/lib/net/zigbee/ieee802154/includes \
			-I$(TOSROOT)/tos/lib/net/zigbee/ieee802154/macTDBS \
			-I$(TOSROOT)/tos/lib/net/zigbee/ieee802154/phy \
			-I$(TOSROOT)/tos/lib/net/zigbee/ieee802154/timerasyncTDBS \
			-I$(TOSROOT)/tos/lib/net/zigbee/ieee802154/interfaces \
			-I$(TOSROOT)/tos/lib/net/zigbee/ieee802154/interfaces/mac \
			-I$(TOSROOT)/tos/lib/net/zigbee/ieee802154/interfaces/phy \
			-I$(TOSROOT)/tos/lib/net/zigbee/cc2420 \
			-I$(TOSROOT)/tos/lib/net/zigbee/ieee802154/interfaces/nwk \
			-I$(TOSROOT)/tos/lib/net/zigbee/ieee802154/nwk\



else
PFLAGS += -DTKN154_MAC
PFLAGS += -I$(TOSROOT)/tos/lib/mac/tkn154 \
	-I$(TOSROOT)/tos/lib/mac/tkn154/dummies \
	-I$(TOSROOT)/tos/lib/mac/tkn154/interfaces/MCPS \
	-I$(TOSROOT)/tos/lib/mac/tkn154/interfaces/MLME \
	-I$(TOSROOT)/tos/lib/mac/tkn154/interfaces/private \
	-I$(TOSROOT)/tos/lib/mac/tkn154/interfaces/public\
\
-I$(TOSROOT)/tos/lib/net/zigbee/wrapper\
-I$(TOSROOT)/tos/lib/net/zigbee/wrapper/interfaces/mac\
-I$(TOSROOT)/tos/lib/net/zigbee/wrapper/includes \
-I$(TOSROOT)/tos/lib/net/zigbee/ieee802154/interfaces/nwk \
 -I$(TOSROOT)/tos/lib/net/zigbee/ieee802154/nwk

  include $(TKN154_PLATFORM_INCLUDE)	

endif

include $(MAKERULES)		


