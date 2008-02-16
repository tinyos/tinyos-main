COMPONENT=TestDIPC
BUILD_EXTRA_DEPS = DipMsg.py DipDataMsg.py DipMsg.class DipDataMsg.class DipData.class DipInject.class
CFLAGS += -I$(TOSDIR)/lib/net
CFLAGS += -I$(TOSDIR)/lib/net/dip -I$(TOSDIR)/lib/net/dip/interfaces
#CFLAGS += -I$(TOSDIR)/lib/net/drip

CONSTANTS += -DTOSH_DATA_LENGTH=32
CFLAGS += $(CONSTANTS)

CLEAN_EXTRA += DipMsg.py DipDataMsg.py DipData.py DipMsg.java DipDataMsg.java DipData.java DipMsg.class DipDataMsg.class DipData.class DipInject.class

DipMsg.py:
	mig python -target=$(PLATFORM) -python-classname=DipMsg $(CFLAGS) $(TOSDIR)/lib/net/dip/Dip.h dip_msg -o $@

DipDataMsg.py:
	mig python -target=$(PLATFORM) -python-classname=DipDataMsg -python-extends=DipMsg $(CFLAGS) $(TOSDIR)/lib/net/dip/Dip.h dip_data_msg -o $@

DipData.py:
	mig python -target=$(PLATFORM) -python-classname=DipData -python-extends=DipDataMsg $(CFLAGS) $(TOSDIR)/lib/net/dip/Dip.h dip_data -o $@


DipMsg.class: DipMsg.java
	javac -target 1.4 -source 1.4 DipMsg.java

DipDataMsg.class: DipDataMsg.java
	javac -target 1.4 -source 1.4 DipDataMsg.java

DipData.class: DipData.java
	javac -target 1.4 -source 1.4 DipData.java

DipMsg.java:
	mig java -target=$(PLATFORM) -java-classname=DipMsg $(CFLAGS) $(TOSDIR)/lib/net/dip/Dip.h dip_msg -o $@

DipDataMsg.java:
	mig java -target=$(PLATFORM) -java-classname=DipDataMsg -java-extends=DipMsg $(CFLAGS) $(TOSDIR)/lib/net/dip/Dip.h dip_data_msg -o $@

DipData.java:
	mig java -target=$(PLATFORM) -java-classname=DipData -java-extends=DipDataMsg $(CFLAGS) $(TOSDIR)/lib/net/dip/Dip.h dip_data -o $@

DipInject.class:
	javac -target 1.4 -source 1.4 DipInject.java

include $(MAKERULES)
