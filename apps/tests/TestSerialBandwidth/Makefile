COMPONENT=TestSerialAppC
TOSMAKE_PRE_EXE_DEPS += TestSerialMsg.class TestSerial.class
CFLAGS += -DTOSH_DATA_LENGTH=100
TOSMAKE_CLEAN_EXTRA = *.class TestSerialMsg.java

%.class: %.java
	javac $<

TestSerialMsg.java:
	nescc-mig java $(NESC_PFLAGS) $(CFLAGS) -java-classname=TestSerialMsg TestSerial.h TestSerialMsg -o $@

TINYOS_ROOT_DIR?=../../..
include $(TINYOS_ROOT_DIR)/Makefile.include
