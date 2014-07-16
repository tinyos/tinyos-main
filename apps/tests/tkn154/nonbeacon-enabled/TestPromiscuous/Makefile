COMPONENT=TestPromiscuousAppC
CFLAGS +=  -I$(TINYOS_OS_DIR)/lib/printf -DPRINTF_BUFFER_SIZE=1000
CFLAGS += -DIEEE154_SCAN_DISABLED -DIEEE154_BEACON_SYNC_DISABLED -DIEEE154_BEACON_TX_DISABLED -DIEEE154_RXENABLE_DISABLED -DIEEE154_ASSOCIATION_DISABLED -DIEEE154_DISASSOCIATION_DISABLED -DIEEE154_COORD_REALIGNMENT_DISABLED -DIEEE154_COORD_BROADCAST_DISABLED

# To use the TKN15.4 MAC instead of a platform's default MAC protocol first
# include the TinyOS "Makerules" file as usual ...
TINYOS_ROOT_DIR?=../../../../..
include $(TINYOS_ROOT_DIR)/Makefile.include
# ... and then include the TKN15.4 "Makefile.include" file. That's all.
# Hint: type "make <platform> verbose" to see the aggregate include path.
include $(TINYOS_OS_DIR)/lib/mac/tkn154/Makefile.include
