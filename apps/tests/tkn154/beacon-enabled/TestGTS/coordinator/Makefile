COMPONENT=TestGTSAppC
CFLAGS += -DIEEE154_GTS_COORD_ENABLED 
CFLAGS += -I$(shell pwd)/..

CFLAGS += -DIEEE154_PROMISCUOUS_MODE_DISABLED -DTKN154_ACTIVE_MESSAGE_SUPPORT_DISABLED

# To use the TKN15.4 MAC instead of a platform's default MAC protocol first
# include the TinyOS "Makerules" file as usual ...
include $(MAKERULES)

# ... and then include the TKN15.4 "Makefile.include" file. That's all.
# Hint: type "make <platform> verbose" to see the aggregate include path.
include $(TOSDIR)/lib/mac/tkn154/Makefile.include
