COMPONENT=TestADE7753AppC
BUILD_EXTRA_DEPS = TestADE7753Msg.py
CLEAN_EXTRA = TestADE7753Msg.py *.pyc

TestADE7753Msg.py: TestADE7753.h
	nescc-mig python $(NESC_PFLAGS) $(CFLAGS) -python-classname=TestADE7753Msg TestADE7753.h testade7753_msg -o $@

CFLAGS += -I$(TINYOS_OS_DIR)/chips/ade7753
CFLAGS += -DTOSH_DATA_LENGTH=100

#CFLAGS += -I$(TINYOS_OS_DIR)/lib/diagmsg
#CFLAGS += -DDIAGMSG_RADIO
#CFLAGS += -DDEBUG_ADE7753


TINYOS_ROOT_DIR?=../../../..
include $(TINYOS_ROOT_DIR)/Makefile.include

