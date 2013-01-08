COMPONENT=PppRouterC
#PFLAGS += -DENABLE_SPI0_DMA
PFLAGS += -DCC2420_DEF_CHANNEL=13

#IRIS Software-Ack
CFLAGS+=-DRF230_HARDWARE_ACK
CFLAGS+=-DCC2420_HARDWARE_ACK

CFLAGS += -DHARDWAREACK
CFLAGS += -DCC2420_HARDWAREACK
CFLAGS += -DRF230_HARDWAREACK

CFLAGS+=-DCC2420_HW_ACKNOWLEDGEMENTS 
CFLAGS+=-DRF230_HW_ACKNOWLEDGEMENTS 
#CFLAGS += -DSOFTWAREACK_TIMEOUT=3000 

# use rpl
PFLAGS += -DRPL_ROUTING -DRPL_STORING_MODE -I$(LOWPAN_ROOT)/tos/lib/net/rpl
# PFLAGS += -DRPL_OF_MRHOF

# and ppp
PFLAGS += -I$(TOSDIR)/lib/ppp
PFLAGS += -I$(TOSDIR)/lib/fragpool

# this works around fragmentation in the RX buffer pool
PFLAGS += -DPPP_HDLC_RX_FRAME_LIMIT=1 -DPPP_HDLC_TX_FRAME_LIMIT=8

# if you set this, the stack won't use dhcp to assign addresses -- it
# will use this prefix combined with TOS_NODE_ID
PFLAGS += -DIN6_PREFIX=\"fec0::\"

# derive short address from the dhcp address assignment, if possible
PFLAGS += -DBLIP_DERIVE_SHORTADDRS

# tell the 6lowpan layer to not generate hc-compressed headers
#PFLAGS += -DLIB6LOWPAN_HC_VERSION=-1

#LPL FLAGS
#CFLAGS += -DLOW_POWER_LISTENING
#CFLAGS += -DLPL_SLEEP_INTERVAL=512
#CFLAGS += -DBLIP_L2_RETRIES=2
#CFLAGS += -DBLIP_L2_DELAY=2048 
#CFLAGS += -DDUTY_ON_TIME=15

include $(MAKERULES)
