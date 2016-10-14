COMPONENT=SnifferAppC

ifndef $(TOS_CHANNEL)
  $(warning TOS_CHANNEL is not set. Using default channel 11)
  TOS_CHANNEL := 11
endif

CFLAGS += -DJN516_SNIFFER_CHANNEL=$(TOS_CHANNEL)

TINYOS_ROOT_DIR?=../../../..
include $(TINYOS_ROOT_DIR)/Makefile.include

