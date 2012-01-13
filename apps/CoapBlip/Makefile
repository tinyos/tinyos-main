COMPONENT=CoapBlipC

# uncomment this for network programming support
# BOOTLOADER=tosboot

#CFLAGS += -DCC2420_DEF_CHANNEL=21
#CFLAGS += -DRF230_DEF_CHANNEL=16
#CFLAGS += -DCC2420_DEF_RFPOWER=4

# Enable Low Power Listening
#CFLAGS += -DLOW_POWER_LISTENING
#CFLAGS += -DLPL_SLEEP_INTERVAL=512

# disables support for the AM stack, which somewhat reduces code size
# and compresses packet formats.  If you want to use other tinyos
# protocols which are AM-based, you should not include this.
#CFLAGS += -DIEEE154FRAMES_ENABLED

# lib6lowpan contains inet_ntop6 and inet_pton6 to process ascii
# representations of IPv6 addresses.  You can remove them to save some
# code if you don't use them
# CFLAGS += -DNO_LIB6LOWPAN_ASCII

# you can compile with or without a routing protocol... of course,
# without it, you will only be able to use link-local communication.
PFLAGS += -DRPL_ROUTING -DRPL_STORING_MODE -I$(LOWPAN_ROOT)/tos/lib/net/rpl
#PFLAGS += -DRPL_OF_MRHOF -DRPL_ROOT_ADDR=1

# if you set this, the stack won't use dhcp to assign addresses -- it
# will use this prefix combined with TOS_NODE_ID
PFLAGS += -DIN6_PREFIX=\"fec0::\"

# printf debugs. works only on telosb/tmote sky.
# CFLAGS += -DNEW_PRINTF_SEMANTICS -DPRINTFUART_ENABLED
# uncomment this line if you are having problems displaying the new printf semantics
# CFLAGS += -DPRINTF_BUFFER_SIZE=1024

################ CoAP Server ###############################
CFLAGS += -DCOAP_SERVER_ENABLED
# port where server is listening
CFLAGS += -DCOAP_SERVER_PORT=61616L
#set max uri length
CFLAGS += -DMAX_URI_LENGTH=5
# set available resources.
# Don't forget to change CFLAG: NUM_URIS!!!!!
CFLAGS += -DNUM_URIS=1

#CFLAGS += -DCOAP_RESOURCE_TEMP
#CFLAGS += -DCOAP_RESOURCE_HUM
#CFLAGS += -DCOAP_RESOURCE_VOLT
#CFLAGS += -DCOAP_RESOURCE_ALL #TEMP + HUM + VOLT

#CFLAGS += -DCOAP_RESOURCE_KEY

CFLAGS += -DCOAP_RESOURCE_LED

#CFLAGS += -DCOAP_RESOURCE_ROUTE

# timeout in milliseconds for sending PreACK
CFLAGS += -DCOAP_PREACK_TIMEOUT=500

#CFLAGS += -DINCLUDE_WELLKNOWN

################ CoAP Client ################################
#CFLAGS += -DCOAP_CLIENT_ENABLED
# client destination port
CFLAGS += -DCOAP_CLIENT_PORT=61617L
# client IPv6 destination address
CFLAGS += -DCOAP_CLIENT_DEST=\"fec0::100\"

CFLAGS += -I.
include $(MAKERULES)
