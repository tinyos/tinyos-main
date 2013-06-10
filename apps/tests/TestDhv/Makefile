COMPONENT=TestDhvC
TOSMAKE_PRE_EXE_DEPS = DhvMsg.py DhvDataMsg.py DhvMsg.class DhvDataMsg.class DhvData.class DhvInject.class DhvTestMsg.class
CFLAGS += -I$(TINYOS_OS_DIR)/lib/net
#CFLAGS += -DLOW_POWER_LISTENING
#CFLAGS += -DLPL_DEF_LOCAL_SLEEP=512
#CFLAGS += -DLPL_DEF_RX_SLEEP=512
#CFLAGS += -DDELAY_AFTER_RECEIVE=20
CFLAGS += -I$(TINYOS_OS_DIR)/lib/net/dhv -I$(TINYOS_OS_DIR)/lib/net/dhv/interfaces

CONSTANTS += -DTOSH_DATA_LENGTH=32
CFLAGS += $(CONSTANTS)

TOSMAKE_CLEAN_EXTRA += DhvMsg.py DhvDataMsg.py DhvData.py DhvMsg.java DhvDataMsg.java DhvData.java DhvMsg.class DhvDataMsg.class DhvData.class DhvInject.class DhvTestMsg.class DhvTestMsg.java

DhvMsg.py:
	nescc-mig python $(NESC_PFLAGS) -python-classname=DhvMsg $(CFLAGS) $(TINYOS_OS_DIR)/lib/net/dhv/Dhv.h dhv_msg -o $@

DhvDataMsg.py:
	nescc-mig python $(NESC_PFLAGS) -python-classname=DhvDataMsg -python-extends=DhvMsg $(CFLAGS) $(TINYOS_OS_DIR)/lib/net/dhv/Dhv.h dhv_data_msg -o $@

DhvData.py:
	nescc-mig python $(NESC_PFLAGS) -python-classname=DhvData -python-extends=DhvDataMsg $(CFLAGS) $(TINYOS_OS_DIR)/lib/net/dhv/Dhv.h dhv_data -o $@

DhvTestMsg.class: DhvTestMsg.java
	javac DhvTestMsg.java

DhvMsg.class: DhvMsg.java
	javac  DhvMsg.java

DhvDataMsg.class: DhvDataMsg.java
	javac  DhvDataMsg.java

DhvData.class: DhvData.java
	javac  DhvData.java

DhvTestMsg.java:
	nescc-mig java -java-classname=DhvTestMsg $(CFLAGS) $(TINYOS_OS_DIR)/lib/net/dhv/Dhv.h dhv_test_msg -o $@

DhvMsg.java:
	nescc-mig java -java-classname=DhvMsg $(CFLAGS) $(TINYOS_OS_DIR)/lib/net/dhv/Dhv.h dhv_msg -o $@

DhvDataMsg.java:
	nescc-mig java -java-classname=DhvDataMsg -java-extends=DhvMsg $(CFLAGS) $(TINYOS_OS_DIR)/lib/net/dhv/Dhv.h dhv_data_msg -o $@

DhvData.java:
	nescc-mig java -java-classname=DhvData -java-extends=DhvDataMsg $(CFLAGS) $(TINYOS_OS_DIR)/lib/net/dhv/Dhv.h dhv_data -o $@

DhvInject.class:
	javac  DhvInject.java

TINYOS_ROOT_DIR?=../../..
include $(TINYOS_ROOT_DIR)/Makefile.include
