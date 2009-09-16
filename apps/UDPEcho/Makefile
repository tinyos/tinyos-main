COMPONENT=UDPEchoC

# uncomment this for network programming support
# BOOTLOADER=tosboot

CFLAGS += -DCC2420_DEF_CHANNEL=15
CFLAGS += -DRF230_DEF_CHANNEL=15
# CFLAGS += -DCC2420_DEF_RFPOWER=4

# disables support for the AM stack, which somewhat reduces code size
# and compresses packet formats.  If you want to use other tinyos
# protocols which are AM-based, you should not include this.
CFLAGS += -DIEEE154FRAMES_ENABLED


# lib6lowpan contains inet_ntop6 and inet_pton6 to process ascii
# representations of IPv6 addresses.  You can remove them to save some
# code if you don't use them
# CFLAGS += -DNO_LIB6LOWPAN_ASCII

# if this is set, motes will send debugging information to the address
# listed.
# CFLAGS += -DREPORT_DEST=\"2001:470:1f04:56d::64\"

# printf debugs.  works only on telosb/tmote sky
# CFLAGS += -DPRINTFUART_ENABLED


include $(MAKERULES)

