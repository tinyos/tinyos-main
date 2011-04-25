COMPONENT=TestPacketTimeSyncAppC
PFLAGS+=-DTIMESYNC_TMICRO
PFLAGS+=-DTASKLET_IS_TASK
#PFLAGS+=-DRADIO_DEBUG -DRADIO_DEBUG_MESSAGES
BUILD_EXTRA_DEPS = PingMsg.class PongMsg.class TestPacketTimeSync.class
CLEAN_EXTRA = *.class PongMsg.java PingMsg.java

PingMsg.class: PingMsg.java
	javac PingMsg.java

PongMsg.class: PongMsg.java
	javac PongMsg.java

PingMsg.java: TestPacketTimeSync.h
	mig java -target=$(PLATFORM) $(CFLAGS) -java-classname=PingMsg TestPacketTimeSync.h real_ping_msg -o $@

PongMsg.java: TestPacketTimeSync.h
	mig java -target=$(PLATFORM) $(CFLAGS) -java-classname=PongMsg TestPacketTimeSync.h pong_msg -o $@

TestPacketTimeSync.class: PongMsg.class PingMsg.class
	javac TestPacketTimeSync.java

include $(MAKERULES)

