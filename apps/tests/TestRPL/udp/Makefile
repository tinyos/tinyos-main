COMPONENT=TestRPLAppC

# NB :
# DEFAULT_LOCAL_GROUP=0xabcd

# radio settings
CFLAGS+=-DCC2420_DEF_CHANNEL=25
CFLAGS+=-DCC2520_DEF_CHANNEL=25

################################################################################
### Set the addressing scheme
################################################################################

# Use IN6_PREFIX with static addressing modes
PFLAGS += -DIN6_PREFIX=\"aaaa::/64\"
# Use BLIP Neighbor Discovery to autoconfigure an address
PFLAGS += -DBLIP_ADDR_AUTOCONF=0
# Use RPL and prefix information in DIO messages to autoconfigure an address
PFLAGS += -DRPL_ADDR_AUTOCONF=0

################################################################################
### Configure BLIP
################################################################################

# Configure the Neighbor Discovery mechanism
PFLAGS += -DBLIP_SEND_ROUTER_SOLICITATIONS=0
PFLAGS += -DBLIP_SEND_ROUTER_ADVERTISEMENTS=0

# Configure the number of times BLIP tries to send a packet and how long it
# waits between attempts
PFLAGS += -DBLIP_L2_RETRIES=3
PFLAGS += -DBLIP_L2_DELAY=103

# Configure how many of the 6LoWPAN headers we support
#PFLAGS += -DLIB6LOWPAN_FULL=1

# Configure the header compression for 6LoWPAN
PFLAGS += -DLIB6LOWPAN_HC_VERSION=6

# Keep statistics about various BLIP/IPv6 parameters. See BlipStatistics.h
#PFLAGS += -DBLIP_STATS
#PFLAGS += -DBLIP_STATS_IP_MEM

################################################################################
### Configure RPL
################################################################################

# Include the RPL layer if set to 1
PFLAGS += -DRPL_ROUTING=1

# If set keep routing information in each node. If not the root must keep all
# routing information.
PFLAGS += -DRPL_STORING_MODE=1

# Choose the objective function RPL should use
PFLAGS += -DRPL_OF_0=1
PFLAGS += -DRPL_OF_MRHOF=0

################################################################################
### Configure LPL
################################################################################

#PFLAGS += -DLOW_POWER_LISTENING
#PFLAGS += -DLPL_SLEEP_INTERVAL=512
#PFLAGS += -DLPL_DEF_LOCAL_WAKEUP=512
#PFLAGS += -DLPL_DEF_REMOTE_WAKEUP=512

################################################################################
### Configure printf() output
################################################################################

PFLAGS += -DNEW_PRINTF_SEMANTICS -DPRINTFUART_ENABLED -DPRINTF_BUFFER_SIZE=1024

################################################################################
### Configure this application
################################################################################

# 5 second packet generation interval
CFLAGS+=-DPACKET_INTERVAL=5120UL

CFLAGS+=-DRPL_ROOT_ADDR=11

<<<<<<< HEAD
# enable printf
CFLAGS += -DNEW_PRINTF_SEMANTICS -DPRINTFUART_ENABLED -DPRINTF_BUFFER_SIZE=1024
=======


GOALS += blip rpl

>>>>>>> BLIP+RPL: updating /apps
TINYOS_ROOT_DIR?=../../../..
include $(TINYOS_ROOT_DIR)/Makefile.include
