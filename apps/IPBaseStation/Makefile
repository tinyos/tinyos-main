COMPONENT=BaseStationC

# radio options.  channel settings will be overridden by the driver
# CFLAGS += -DCC2420_DEF_RFPOWER=4

# this is necessary, otherwise we will allocate a heap by including
# the lowpan target
CFLAGS += -DNO_IP_MALLOC

#
# debugging
#

# filter packets based on a specified topology
# PFLAGS += -I../UDPEcho/NodeConnectivity -DSW_TOPOLOGY

# part of the test harness
# CFLAGS += -DDBG_TRACK_FLOWS

# for simulation
# CFLAGS += -DBASESTATION_ID=100

include $(MAKERULES)

