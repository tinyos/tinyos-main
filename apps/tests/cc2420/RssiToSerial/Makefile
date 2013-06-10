COMPONENT=RssiToSerialC
TOSMAKE_PRE_EXE_DEPS = RssiSerialMsg.java SpecAnalyzer.class
TOSMAKE_CLEAN_EXTRA = *.class RssiSerialMsg.java

RssiSerialMsg.java: RssiToSerial.h
	nescc-mig java $(NESC_PFLAGS) $(CFLAGS) -java-classname=RssiSerialMsg RssiToSerial.h rssi_serial_msg -o $@

SpecAnalyzer.class: $(wildcard *.java) SpecAnalyzer.java
	javac *.java

TINYOS_ROOT_DIR?=../../../..
include $(TINYOS_ROOT_DIR)/Makefile.include
