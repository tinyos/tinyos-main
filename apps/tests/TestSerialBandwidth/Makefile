COMPONENT=TestSerialAppC
BUILD_EXTRA_DEPS += TestSerialMsg.class TestSerial.class
CFLAGS += -DTOSH_DATA_LENGTH=100

%.class: %.java
	javac $<

TestSerialMsg.java:
	mig java -target=$(PLATFORM) $(CFLAGS) -java-classname=TestSerialMsg TestSerial.h TestSerialMsg -o $@

include $(MAKERULES)

