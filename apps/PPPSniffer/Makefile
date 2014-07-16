COMPONENT=PPPSnifferC

# this is necessary, otherwise we will allocate a heap by including
# the lowpan target
CFLAGS += -DNO_IP_MALLOC

# this aligns the 802.15.4 payload on the data field of a message_t.
# very convenient for forwarding, and means we don't have to do a
# memmove.  This doesn't mean that motes running blip also need this--
# they can use IFRAMES or IEEE154FRAMES
#CFLAGS += -DIEEE154FRAMES_ENABLED

#enable capturing in CC2420XDriverLayerP.nc
CFLAGS += -DPPPSNIFFER

# also receive big blip packets....
CFLAGS += -DTOSH_DATA_LENGTH=120

CFLAGS += -DCC2420X_DEF_CHANNEL=26

TOSMAKE_PATH += .
CFLAGS += -I$(TINYOS_OS_DIR)/lib/diagmsg
PFLAGS += -I$(TINYOS_OS_DIR)/lib/ppp
PFLAGS += -I$(TINYOS_OS_DIR)/lib/fragpool

# -Os breaks the PPP or serial stack somehow...
OPTFLAGS += -O2

TINYOS_ROOT_DIR?=../..
include $(TINYOS_ROOT_DIR)/Makefile.include
