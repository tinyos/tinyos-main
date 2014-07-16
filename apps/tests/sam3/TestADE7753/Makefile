COMPONENT=TestADE7753AppC
TOSMAKE_PRE_EXE_DEPS = TestADE7753Msg.py
TOSMAKE_CLEAN_EXTRA = TestADE7753Msg.py *.pyc

TestADE7753Msg.py: TestADE7753.h
	nescc-mig python $(NESC_PFLAGS) $(CFLAGS) -python-classname=TestADE7753Msg TestADE7753.h testade7753_msg -o $@

CFLAGS += -I$(TINYOS_OS_DIR)/chips/ade7753
CFLAGS += -DTOSH_DATA_LENGTH=100

TINYOS_ROOT_DIR?=../../../..
include $(TINYOS_ROOT_DIR)/Makefile.include
