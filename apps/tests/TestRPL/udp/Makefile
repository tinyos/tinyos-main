COMPONENT=TestRPLAppC

# NB : 
# DEFAULT_LOCAL_GROUP=0xabcd

# radio settings
CFLAGS+=-DCC2420_DEF_CHANNEL=25
CFLAGS+=-DCC2520_DEF_CHANNEL=25

# enable RPL
CFLAGS+=-DRPL_ROUTING -DRPL_STORING_MODE -I$(LOWPAN_ROOT)/tos/lib/net/rpl
# but not MRHOF
# CFLAGS+=-DRPL_OF_MRHOF

# use short addresses so it's easier to debug
CFLAGS+=-DBLIP_DERIVE_SHORTADDRS

# the sleep interval needs to be set the same for all participating devices
# CFLAGS += -DLOW_POWER_LISTENING -DLPL_SLEEP_INTERVAL=200

# also modifiy blip's L2 parameters to reduce media overload
CFLAGS +=-DBLIP_L2_RETRIES=3 -DBLIP_L2_DELAY=103

# 5 second packet generation interval
CFLAGS+=-DPACKET_INTERVAL=5120UL

CFLAGS+=-DRPL_ROOT_ADDR=11
#USE_CPPOPT = -fno-rtti -fno-exceptions
#PFLAGS+=-DIN6_PREFIX=\"fec0::\"
PFLAGS+=-DIN6_PREFIX=\"aaaa::/64\"

# enable printf
CFLAGS += -DNEW_PRINTF_SEMANTICS -DPRINTFUART_ENABLED -DPRINTF_BUFFER_SIZE=1024
include $(MAKERULES)
