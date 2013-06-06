#SENSORBOARD = mts300
PFLAGS += -DMTS300CA
PFLAGS += -I%T/lib/net/ctp -I%T/lib/net -I%T/lib/net/4bitle -I%T/lib/net/drip
COMPONENT=AntiTheftAppC

#CFLAGS += -DLOW_POWER_LISTENING
#CFLAGS += -DLPL_DEF_LOCAL_WAKEUP=512
#CFLAGS += -DLPL_DEF_REMOTE_WAKEUP=512
#CFLAGS += -DDELAY_AFTER_RECEIVE=20

TINYOS_ROOT_DIR?=../../..
include $(TINYOS_ROOT_DIR)/Makefile.include
$(call TOSMake_include_sensor,mts300)
