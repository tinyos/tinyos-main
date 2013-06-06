COMPONENT=PppRouterC
# PFLAGS += -DENABLE_SPI0_DMA
#PFLAGS += -DCC2420_DEF_CHANNEL=21

#DEFAULT_LOCAL_GROUP = 0xCA

# use rpl
PFLAGS += -DRPL_ROUTING -DRPL_STORING_MODE -I$(TINYOS_OS_DIR)/lib/net/rpl
# PFLAGS += -DRPL_OF_MRHOF

# and ppp
PFLAGS += -I$(TINYOS_OS_DIR)/lib/ppp
PFLAGS += -I$(TINYOS_OS_DIR)/lib/fragpool

# this works around fragmentation in the RX buffer pool
PFLAGS += -DPPP_HDLC_RX_FRAME_LIMIT=1 -DPPP_HDLC_TX_FRAME_LIMIT=8

# Set this when you want to use statically assigned addresses. The stack will
# not use DHCP in that case.
PFLAGS += -DIN6_PREFIX=\"fec0::\"
#PFLAGS += -DIN6_PREFIX=\"2a01:198:56c:1000::\"
#PFLAGS += -DIN6_PREFIX=\"2a01:c911:0:2125::\"
#PFLAGS += -DIN6_PREFIX=\"2a01:c911:0:212d::\"

# derive short address from the dhcp address assignment, if possible
PFLAGS += -DBLIP_DERIVE_SHORTADDRS

TINYOS_ROOT_DIR?=../..
include $(TINYOS_ROOT_DIR)/Makefile.include
