COMPONENT=TestSerialAppC
BUILD_EXTRA_DEPS += TestSerial.class
CLEAN_EXTRA = *.class TestSerialMsg.java

TestSerial.class: $(wildcard *.java) TestSerialMsg.java
	javac -target 1.4 -source 1.4 *.java

TestSerialMsg.java:
	nescc-mig java -I$(TINYOS_OS_DIR)/platforms/null $(CFLAGS) -java-classname=TestSerialMsg TestSerial.h test_serial_msg -o $@


TINYOS_ROOT_DIR?=../../..
include $(TINYOS_ROOT_DIR)/Makefile.include

