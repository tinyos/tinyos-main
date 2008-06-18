# Top-level Makefile for tools/java

INITIAL_TARGETS = SerialPacket.class SerialPacket.java

ROOT = ../../..
include $(ROOT)/Makefile.include

TOS=$(shell ncc -print-tosdir)
SERIAL_H = $(TOSDIR)/lib/serial/Serial.h

SerialPacket.java: $(SERIAL_H) FORCE
	mig -o $@ -java-classname=net.tinyos.message.SerialPacket java $(SERIAL_H) serial_packet -I$(TOSDIR)/types
