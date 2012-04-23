COMPONENT=CoapPppC

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

# ppp
PFLAGS += -I$(TOSDIR)/lib/ppp
PFLAGS += -I$(TOSDIR)/lib/fragpool

# this works around fragmentation in the RX buffer pool
PFLAGS += -DPPP_HDLC_RX_FRAME_LIMIT=1 -DPPP_HDLC_TX_FRAME_LIMIT=8

# if you set this, the stack won't use dhcp to assign addresses -- it
# will use this prefix combined with TOS_NODE_ID
PFLAGS += -DIN6_PREFIX=\"fec0::\"

# printf debugs. works only on telosb/tmote sky.
# CFLAGS += -DNEW_PRINTF_SEMANTICS -DPRINTFUART_ENABLED
# uncomment this line if you are having problems displaying the new printf semantics
# CFLAGS += -DPRINTF_BUFFER_SIZE=1024

PFLAGS += -DBLIP_NO_RADIO

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

#CFLAGS += -DCOAP_RESOURCE_GIO_PINS   #GIO0, GIO1, GIO2 & GIO3 of TelosB
#CFLAGS += -DCOAP_RESOURCE_DEV_0   #GIO0 of TelosB
#CFLAGS += -DCOAP_RESOURCE_DEV_1   #GIO1 of TelosB
#CFLAGS += -DCOAP_RESOURCE_DEV_2   #GIO2 of TelosB
#CFLAGS += -DCOAP_RESOURCE_DEV_3   #GIO3 of TelosB

#CFLAGS += -DCOAP_RESOURCE_ETSI_IOT_TEST
#CFLAGS += -DCOAP_RESOURCE_ETSI_IOT_SEPARATE
#CFLAGS += -DCOAP_RESOURCE_ETSI_IOT_SEGMENT

# timeout in milliseconds for sending PreACK
CFLAGS += -DCOAP_PREACK_TIMEOUT=500

################ CoAP Client ################################
#CFLAGS += -DCOAP_CLIENT_ENABLED
# client destination port
CFLAGS += -DCOAP_CLIENT_PORT=61617L
# client IPv6 destination address
CFLAGS += -DCOAP_CLIENT_DEST=\"fec0::100\"

CFLAGS += -I.
include $(MAKERULES)
