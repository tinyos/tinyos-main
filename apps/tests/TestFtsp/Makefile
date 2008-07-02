BUILD_EXTRA_DEPS = FtspDataLogger.class
CLEAN_EXTRA = *.class TestFtspMsg.java

FtspDataLogger.class: TestFtspMsg.java
	javac *.java

TestFtspMsg.java: TestFtsp.h
	mig java -target=$(PLATFORM) $(CFLAGS) -java-classname=TestFtspMsg TestFtsp.h test_ftsp_msg -o $@

COMPONENT=TestFtspC

PFLAGS += -DTIMESYNC_RATE=3
#PFLAGS += -DTIMESYNC_DEBUG

PFLAGS += -I$(TOSDIR)/lib/ftsp -I$(TOSDIR)/../apps/RadioCountToLeds

include $(MAKERULES)
