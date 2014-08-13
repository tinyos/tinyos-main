COMPONENT=CoapBlipC

# uncomment this for network programming support
# BOOTLOADER=tosboot

#CFLAGS += -DCC2420_DEF_CHANNEL=21
#CFLAGS += -DRF230_DEF_CHANNEL=16
#CFLAGS += -DCC2420_DEF_RFPOWER=4

#DEFAULT_LOCAL_GROUP = 0x1A

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

################################################################################
### Configure RPL
################################################################################
# you can compile with or without a routing protocol... of course,
# without it, you will only be able to use link-local communication.
PFLAGS += -DRPL_ROUTING -DRPL_STORING_MODE -I$(TINYOS_OS_DIR)/lib/net/rpl
#PFLAGS += -DRPL_OF_MRHOF -DRPL_ROOT_ADDR=1
PFLAGS += -DRPL_OF_0=1
PFLAGS += -DRPL_OF_MRHOF=0


# Set this when you want to use statically assigned addresses. The stack will
# not use DHCP in that case.
#PFLAGS += -DIN6_PREFIX=\"2001:638:708:1156::\"
#PFLAGS += -DIN6_PREFIX=\"2a01:198:56c:1000::\"
#PFLAGS += -DIN6_PREFIX=\"2a01:c911:0:212d::\"
PFLAGS += -DIN6_PREFIX=\"fec0::\"

# printf debugs. works only on telosb/tmote sky and when RPL is disabled.
# CFLAGS += -DNEW_PRINTF_SEMANTICS -DPRINTFUART_ENABLED
# uncomment this line if you are having problems displaying the new printf semantics
# CFLAGS += -DPRINTF_BUFFER_SIZE=1024

################ CoAP Server ###############################
CFLAGS += -DCOAP_SERVER_ENABLED
# port where server is listening
#CFLAGS += -DCOAP_SERVER_PORT=5683L
#set max uri length
CFLAGS += -DMAX_URI_LENGTH=14
# set max sensor name length for JSON and XML representation
CFLAGS += -DMAX_SENSOR_NAME_LENGTH=12

# set available resources:

# resource for POST and DELETE support
#CFLAGS += -DCOAP_RESOURCE_DEFAULT

# resources to access sensors
#CFLAGS += -DCOAP_RESOURCE_TEMP
#CFLAGS += -DCOAP_RESOURCE_HUM
#CFLAGS += -DCOAP_RESOURCE_VOLT
#CFLAGS += -DCOAP_RESOURCE_ALL #TEMP + HUM + VOLT # enable the 3 above as well!!

#CFLAGS += -DCOAP_RESOURCE_KEY

CFLAGS += -DCOAP_RESOURCE_LED

#CFLAGS += -DCOAP_RESOURCE_ROUTE

#CFLAGS += -DCOAP_RESOURCE_GIO_PINS   #GIO0, GIO1, GIO2 & GIO3 of TelosB
#CFLAGS += -DCOAP_RESOURCE_DEV_0   #GIO0 of TelosB
#CFLAGS += -DCOAP_RESOURCE_DEV_1   #GIO1 of TelosB
#CFLAGS += -DCOAP_RESOURCE_DEV_2   #GIO2 of TelosB
#CFLAGS += -DCOAP_RESOURCE_DEV_3   #GIO3 of TelosB

# resources for ETSI interoperability test
#CFLAGS += -DCOAP_RESOURCE_ETSI_IOT_VALIDATE
#CFLAGS += -DCOAP_RESOURCE_ETSI_IOT_SEGMENT
#CFLAGS += -DCOAP_RESOURCE_ETSI_IOT_SEPARATE
#CFLAGS += -DCOAP_RESOURCE_ETSI_IOT_LOCATION_QUERY
#CFLAGS += -DCOAP_RESOURCE_ETSI_IOT_QUERY
#CFLAGS += -DCOAP_RESOURCE_ETSI_IOT_LARGE
#CFLAGS += -DCOAP_RESOURCE_ETSI_IOT_OBSERVE
#CFLAGS += -DCOAP_RESOURCE_ETSI_IOT_MULTI_FORMAT
#CFLAGS += -DCOAP_RESOURCE_ETSI_IOT_LINK

# resources for IPSO profile
#CFLAGS += -DCOAP_RESOURCE_IPSO_DEV_MFG
#CFLAGS += -DCOAP_RESOURCE_IPSO_DEV_MDL
#CFLAGS += -DCOAP_RESOURCE_IPSO_DEV_SER
#CFLAGS += -DCOAP_RESOURCE_IPSO_DEV_N
#CFLAGS += -DCOAP_RESOURCE_IPSO_DEV_NAME_PREFIX=\"coap_node_\"
#CFLAGS += -DCOAP_RESOURCE_IPSO_DEV_BAT

# set PDU size
# default: 127
# XML: >165
# Link resource: 1024
CFLAGS += -DCOAP_MAX_PDU_SIZE=127

# set supported content types
CFLAGS += -DCOAP_CONTENT_TYPE_PLAIN
#CFLAGS += -DCOAP_CONTENT_TYPE_XML
#CFLAGS += -DCOAP_CONTENT_TYPE_BINARY
#CFLAGS += -DCOAP_CONTENT_TYPE_JSON

# disables observe
CFLAGS += -DWITHOUT_OBSERVE

# disables block-wise transfer
CFLAGS += -DWITHOUT_BLOCK

# disables .well-known/core resource
CFLAGS += -DWITHOUT_WELLKNOWN

# don't include textual representation of error code in payload
CFLAGS += -DSHORT_ERROR_RESPONSE

# timeout in milliseconds for sending PreACK
CFLAGS += -DCOAP_PREACK_TIMEOUT=1000

################ CoAP Client ################################
#CFLAGS += -DCOAP_CLIENT_ENABLED
# client destination port
CFLAGS += -DCOAP_CLIENT_PORT=61617L
# client IPv6 destination address
CFLAGS += -DCOAP_CLIENT_DEST=\"fec0::100\"
#CFLAGS += -DCOAP_CLIENT_DEST=\"2a01:c911:0:212d::100\"
#CFLAGS += -DCOAP_CLIENT_DEST=\"2a01:c911:0:2120:215:58ff:fe0b:8bb8\"

CFLAGS += -I.
TINYOS_ROOT_DIR?=../..
include $(TINYOS_ROOT_DIR)/Makefile.include
