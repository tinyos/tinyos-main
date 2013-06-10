TOSMAKE_PRE_EXE_DEPS = FtspDataLogger.class
TOSMAKE_CLEAN_EXTRA = *.class TestFtspMsg.java

FtspDataLogger.class: TestFtspMsg.java
	javac *.java

TestFtspMsg.java: TestFtsp.h
	nescc-mig java $(NESC_PFLAGS) $(CFLAGS) -java-classname=TestFtspMsg TestFtsp.h test_ftsp_msg -o $@

COMPONENT=TestFtspAppC

PFLAGS += -DTIMESYNC_RATE=3

PFLAGS += -I$(TINYOS_OS_DIR)/lib/ftsp -I$(TINYOS_OS_DIR)/../apps/RadioCountToLeds

TINYOS_ROOT_DIR?=../../../..
include $(TINYOS_ROOT_DIR)/Makefile.include
