AUTOMAKE_OPTIONS = foreign

INITIAL_TARGETS = SerialPacket.class SerialPacket.java

ROOT = ../../..
include $(ROOT)/Makefile.include

SERIAL_H = $(TINYOS_OS_DIR)/lib/serial/Serial.h
TFLAGS = -I$(TINYOS_OS_DIR)/types

SerialPacket.java: $(SERIAL_H)
	nescc-mig -o $@ $(TFLAGS) -java-classname=net.tinyos.message.SerialPacket java $(SERIAL_H) serial_packet
