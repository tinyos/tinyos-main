README for TestNetworkLpl
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

This is a version of the TestNetworkLpl application that is using the
default LowPowerListening mechanism to reduce the power consumption.

The settings for default lpl are controlled by the following lines
from the Makefile:

  CFLAGS += -DLOW_POWER_LISTENING
  CFLAGS += -DLPL_DEF_LOCAL_WAKEUP=512
  CFLAGS += -DLPL_DEF_REMOTE_WAKEUP=512
  CFLAGS += -DDELAY_AFTER_RECEIVE=20

Known bugs/limitations:

None.
