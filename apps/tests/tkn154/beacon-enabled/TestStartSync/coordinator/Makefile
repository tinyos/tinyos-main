COMPONENT=TestStartSyncAppC
CFLAGS += -I$(shell pwd)/..
CFLAGS += -DIEEE154_SCAN_DISABLED -DIEEE154_BEACON_SYNC_DISABLED

# To use the TKN15.4 MAC instead of a platform's default MAC protocol first
# include the TinyOS "Makerules" file as usual ...
include $(MAKERULES)
# ... and then include the TKN15.4 "Makefile.include" file. That's all.
# Hint: type "make <platform> verbose" to see the aggregate include path.
include $(TOSDIR)/lib/mac/tkn154/Makefile.include
