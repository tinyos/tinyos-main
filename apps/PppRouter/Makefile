COMPONENT=PppRouterC
TOSMAKE_PATH += .
# PFLAGS += -DENABLE_SPI0_DMA
PFLAGS += -DCC2420_DEF_CHANNEL=21

# use rpl
PFLAGS += -DRPL_ROUTING -DRPL_STORING_MODE -I$(LOWPAN_ROOT)/tos/lib/net/rpl

# and ppp
PFLAGS += -I$(TOSDIR)/platforms/telosb 
PFLAGS += -I$(TOSDIR)/lib/ppp -DPLATFORM_SERIAL_RX_BUFFER_SIZE=128
PFLAGS += -I$(TOSDIR)/lib/fragpool

# if you set this, the stack won't use dhcp to assign addresses -- it
# will use this prefix combined with TOS_NODE_ID
PFLAGS += -DIN6_PREFIX=\"fec0::\"

# derive short address from the dhcp address assignment, if possible
# PFLAGS += -DBLIP_DERIVE_SHORTADDRS

include $(MAKERULES)
