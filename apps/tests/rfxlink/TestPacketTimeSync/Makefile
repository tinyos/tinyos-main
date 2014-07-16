COMPONENT=TestPacketTimeSyncAppC
PFLAGS+=-DTIMESYNC_TMICRO
PFLAGS+=-DTASKLET_IS_TASK
TOSMAKE_PRE_EXE_DEPS = PingMsg.class PongMsg.class TestPacketTimeSync.class
TOSMAKE_CLEAN_EXTRA = *.class PongMsg.java PingMsg.java

PingMsg.class: PingMsg.java
	javac PingMsg.java

PongMsg.class: PongMsg.java
	javac PongMsg.java

PingMsg.java: TestPacketTimeSync.h
	nescc-mig java $(NESC_PFLAGS) $(CFLAGS) -java-classname=PingMsg TestPacketTimeSync.h real_ping_msg -o $@

PongMsg.java: TestPacketTimeSync.h
	nescc-mig java $(NESC_PFLAGS) $(CFLAGS) -java-classname=PongMsg TestPacketTimeSync.h pong_msg -o $@

TestPacketTimeSync.class: PongMsg.class PingMsg.class
	javac TestPacketTimeSync.java

TINYOS_ROOT_DIR?=../../../..
include $(TINYOS_ROOT_DIR)/Makefile.include
