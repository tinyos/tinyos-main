COMPONENT=TestDhvC
BUILD_EXTRA_DEPS = DhvMsg.py DhvDataMsg.py DhvMsg.class DhvDataMsg.class DhvData.class DhvInject.class DhvTestMsg.class
CFLAGS += -I$(TOSDIR)/lib/net
#CFLAGS += -DLOW_POWER_LISTENING
#CFLAGS += -DLPL_DEF_LOCAL_SLEEP=512
#CFLAGS += -DLPL_DEF_RX_SLEEP=512
#CFLAGS += -DDELAY_AFTER_RECEIVE=20
CFLAGS += -I$(TOSDIR)/lib/net/dhv -I$(TOSDIR)/lib/net/dhv/interfaces
#CFLAGS += -I$(TOSDIR)/lib/net/dhv -I$(TOSDIR)/lib/net/dhv/interfaces
#CFLAGS += -I$(TOSDIR)/lib/net/drip

CONSTANTS += -DTOSH_DATA_LENGTH=32
CFLAGS += $(CONSTANTS)

CLEAN_EXTRA += DhvMsg.py DhvDataMsg.py DhvData.py DhvMsg.java DhvDataMsg.java DhvData.java DhvMsg.class DhvDataMsg.class DhvData.class DhvInject.class DhvTestMsg.class DhvTestMsg.java

DhvMsg.py:
	mig python -target=$(PLATFORM) -python-classname=DhvMsg $(CFLAGS) $(TOSDIR)/lib/net/dhv/Dhv.h dhv_msg -o $@

DhvDataMsg.py:
	mig python -target=$(PLATFORM) -python-classname=DhvDataMsg -python-extends=DhvMsg $(CFLAGS) $(TOSDIR)/lib/net/dhv/Dhv.h dhv_data_msg -o $@

DhvData.py:
	mig python -target=$(PLATFORM) -python-classname=DhvData -python-extends=DhvDataMsg $(CFLAGS) $(TOSDIR)/lib/net/dhv/Dhv.h dhv_data -o $@

DhvTestMsg.class: DhvTestMsg.java
	javac DhvTestMsg.java

DhvMsg.class: DhvMsg.java
	javac  DhvMsg.java

DhvDataMsg.class: DhvDataMsg.java
	javac  DhvDataMsg.java

DhvData.class: DhvData.java
	javac  DhvData.java

DhvTestMsg.java:
	mig java -target=null -java-classname=DhvTestMsg $(CFLAGS) $(TOSDIR)/lib/net/dhv/Dhv.h dhv_test_msg -o $@

DhvMsg.java:
	mig java -target=null -java-classname=DhvMsg $(CFLAGS) $(TOSDIR)/lib/net/dhv/Dhv.h dhv_msg -o $@

DhvDataMsg.java:
	mig java -target=null -java-classname=DhvDataMsg -java-extends=DhvMsg $(CFLAGS) $(TOSDIR)/lib/net/dhv/Dhv.h dhv_data_msg -o $@

DhvData.java:
	mig java -target=null -java-classname=DhvData -java-extends=DhvDataMsg $(CFLAGS) $(TOSDIR)/lib/net/dhv/Dhv.h dhv_data -o $@

DhvInject.class:
	javac  DhvInject.java

include $(MAKERULES)
