COMPONENT=TestDipC
TOSMAKE_PRE_EXE_DEPS = DipMsg.py DipDataMsg.py DipMsg.class DipDataMsg.class DipData.class DipInject.class
CFLAGS += -I$(TINYOS_OS_DIR)/lib/net
CFLAGS += -I$(TINYOS_OS_DIR)/lib/net/dip -I$(TINYOS_OS_DIR)/lib/net/dip/interfaces

CONSTANTS += -DTOSH_DATA_LENGTH=32
CFLAGS += $(CONSTANTS)

# LPL FLAGS
#CFLAGS += -DLOW_POWER_LISTENING
#CFLAGS += -DLPL_DEF_LOCAL_WAKEUP=512
#CFLAGS += -DLPL_DEF_REMOTE_WAKEUP=512
#CFLAGS += -DDELAY_AFTER_RECEIVE=20

TOSMAKE_CLEAN_EXTRA += DipMsg.py DipDataMsg.py DipData.py DipMsg.java DipDataMsg.java DipData.java DipMsg.class DipDataMsg.class DipData.class DipInject.class

DipMsg.py:
	nescc-mig python $(NESC_PFLAGS) -python-classname=DipMsg $(CFLAGS) $(TINYOS_OS_DIR)/lib/net/dip/Dip.h dip_msg -o $@

DipDataMsg.py:
	nescc-mig python $(NESC_PFLAGS) -python-classname=DipDataMsg -python-extends=DipMsg $(CFLAGS) $(TINYOS_OS_DIR)/lib/net/dip/Dip.h dip_data_msg -o $@

DipData.py:
	nescc-mig python $(NESC_PFLAGS) -python-classname=DipData -python-extends=DipDataMsg $(CFLAGS) $(TINYOS_OS_DIR)/lib/net/dip/Dip.h dip_data -o $@


DipMsg.class: DipMsg.java
	javac -target 1.4 -source 1.4 DipMsg.java

DipDataMsg.class: DipDataMsg.java
	javac -target 1.4 -source 1.4 DipDataMsg.java

DipData.class: DipData.java
	javac -target 1.4 -source 1.4 DipData.java

DipMsg.java:
	nescc-mig java $(NESC_PFLAGS) -java-classname=DipMsg $(CFLAGS) $(TINYOS_OS_DIR)/lib/net/dip/Dip.h dip_msg -o $@

DipDataMsg.java:
	nescc-mig java $(NESC_PFLAGS) -java-classname=DipDataMsg -java-extends=DipMsg $(CFLAGS) $(TINYOS_OS_DIR)/lib/net/dip/Dip.h dip_data_msg -o $@

DipData.java:
	nescc-mig java $(NESC_PFLAGS) -java-classname=DipData -java-extends=DipDataMsg $(CFLAGS) $(TINYOS_OS_DIR)/lib/net/dip/Dip.h dip_data -o $@

DipInject.class:
	javac -target 1.4 -source 1.4 DipInject.java

TINYOS_ROOT_DIR?=../../..
include $(TINYOS_ROOT_DIR)/Makefile.include
