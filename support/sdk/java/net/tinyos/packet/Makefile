# Makefile for tools/java/net/tinyos/packet

INITIAL_TARGETS = Serial.class Serial.java

ROOT = ../../..
include $(ROOT)/Makefile.include

TOS=$(shell ncc -print-tosdir)
SERIAL_H = $(TOS)/lib/serial/Serial.h

Serial.java: $(SERIAL_H) FORCE
	ncg -o $@ -java-classname=net.tinyos.packet.Serial java $(SERIAL_H) Serial.h
