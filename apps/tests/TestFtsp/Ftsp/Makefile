BUILD_EXTRA_DEPS = FtspDataLogger.class
CLEAN_EXTRA = *.class TestFtspMsg.java

FtspDataLogger.class: TestFtspMsg.java
	javac *.java

TestFtspMsg.java: TestFtsp.h
	nescc-mig java $(NESC_PFLAGS) $(CFLAGS) -java-classname=TestFtspMsg TestFtsp.h test_ftsp_msg -o $@

COMPONENT=TestFtspAppC

PFLAGS += -DTIMESYNC_RATE=3
#PFLAGS += -DTIMESYNC_DEBUG

PFLAGS += -I$(TINYOS_OS_DIR)/lib/ftsp -I$(TINYOS_OS_DIR)/../apps/RadioCountToLeds

TINYOS_ROOT_DIR?=../../../..
include $(TINYOS_ROOT_DIR)/Makefile.include
