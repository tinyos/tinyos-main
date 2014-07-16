COMPONENT=TestDataAppC
CFLAGS += -DIEEE154_BEACON_TX_DISABLED
CFLAGS += -I$(shell pwd)/..

# To use the TKN15.4 MAC instead of a platform's default MAC protocol first
# include the TinyOS "Makerules" file as usual ...
TINYOS_ROOT_DIR?=../../../../../..
include $(TINYOS_ROOT_DIR)/Makefile.include
# ... and then include the TKN15.4 "Makefile.include" file. That's all.
# Hint: type "make <platform> verbose" to see the aggregate include path.
include $(TINYOS_OS_DIR)/lib/mac/tkn154/Makefile.include

