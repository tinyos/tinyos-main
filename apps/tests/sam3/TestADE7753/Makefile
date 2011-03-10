COMPONENT=TestADE7753AppC
BUILD_EXTRA_DEPS = TestADE7753Msg.py
CLEAN_EXTRA = TestADE7753Msg.py *.pyc

TestADE7753Msg.py: TestADE7753.h
	mig python -target=$(PLATFORM) $(CFLAGS) -python-classname=TestADE7753Msg TestADE7753.h testade7753_msg -o $@

CFLAGS += -I$(TOSDIR)/chips/ade7753
CFLAGS += -DTOSH_DATA_LENGTH=100

#CFLAGS += -I$(TOSDIR)/lib/diagmsg
#CFLAGS += -DDIAGMSG_RADIO
#CFLAGS += -DDEBUG_ADE7753


include $(MAKERULES)

