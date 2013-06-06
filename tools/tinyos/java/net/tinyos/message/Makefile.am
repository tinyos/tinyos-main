AUTOMAKE_OPTIONS = foreign

INITIAL_TARGETS = SerialPacket.class SerialPacket.java

ROOT = ../../..
include $(ROOT)/Makefile.include

SERIAL_H = $(TINYOS_OS_DIR)/lib/serial/Serial.h

SerialPacket.java: $(SERIAL_H)
	mig -o $@ -java-classname=net.tinyos.message.SerialPacket java $(SERIAL_H) serial_packet -tosdir=$(TINYOS_OS_DIR)
