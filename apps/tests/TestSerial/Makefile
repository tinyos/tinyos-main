COMPONENT=TestSerialAppC
TOSMAKE_PRE_EXE_DEPS += TestSerial.class
TOSMAKE_CLEAN_EXTRA = *.class TestSerialMsg.java

TestSerial.class: $(wildcard *.java) TestSerialMsg.java
	javac -target 1.4 -source 1.4 *.java

TestSerialMsg.java:
	nescc-mig java $(CFLAGS) -java-classname=TestSerialMsg TestSerial.h test_serial_msg -o $@


TINYOS_ROOT_DIR?=../../..
include $(TINYOS_ROOT_DIR)/Makefile.include

