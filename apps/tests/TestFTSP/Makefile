BUILD_EXTRA_DEPS = TestFTSPMsg.class
CLEAN_EXTRA = *.class TestFTSPMsg.java

TestFTSPMsg.class: TestFTSPMsg.java
	javac TestFTSPMsg.java

TestFTSPMsg.java: TestFTSP.h
	mig java -target=$(PLATFORM) $(CFLAGS) -java-classname=TestFTSPMsg TestFTSP.h test_ftsp_msg -o $@

COMPONENT=TestFTSPC

PFLAGS += -v -DTIMESYNC_RATE=10
#PFLAGS += -DTIMESYNC_DEBUG

PFLAGS += -I$(TOSDIR)/lib/FTSP -I$(TOSDIR)/../apps/RadioCountToLeds

include $(MAKERULES)

