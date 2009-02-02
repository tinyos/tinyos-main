COMPONENT=RssiToSerialC
BUILD_EXTRA_DEPS = RssiSerialMsg.java SpecAnalyzer.class
CLEAN_EXTRA = *.class RssiSerialMsg.java

RssiSerialMsg.java: RssiToSerial.h
	mig java -target=$(PLATFORM) $(CFLAGS) -java-classname=RssiSerialMsg RssiToSerial.h rssi_serial_msg -o $@

SpecAnalyzer.class: $(wildcard *.java) SpecAnalyzer.java
	javac *.java

include $(MAKERULES)

