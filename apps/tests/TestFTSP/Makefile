BUILD_EXTRA_DEPS = FTSPDataLogger.class
CLEAN_EXTRA = *.class TestFTSPMsg.java

FTSPDataLogger.class: TestFTSPMsg.java
	javac *.java

TestFTSPMsg.java: TestFTSP.h
	mig java -target=$(PLATFORM) $(CFLAGS) -java-classname=TestFTSPMsg TestFTSP.h test_ftsp_msg -o $@

COMPONENT=TestFTSPC

PFLAGS += -DTIMESYNC_RATE=3
#PFLAGS += -DTIMESYNC_DEBUG

PFLAGS += -I$(TOSDIR)/lib/ftsp -I$(TOSDIR)/../apps/RadioCountToLeds

include $(MAKERULES)
