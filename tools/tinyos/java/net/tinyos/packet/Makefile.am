AUTOMAKE_OPTIONS = foreign

INITIAL_TARGETS = Serial.class Serial.java

ROOT = ../../..
include $(ROOT)/Makefile.include

SERIAL_H = $(TINYOS_OS_DIR)/lib/serial/Serial.h

Serial.java: $(SERIAL_H)
	ncg -o $@ -java-classname=net.tinyos.packet.Serial java $(SERIAL_H) Serial.h -tosdir=$(TINYOS_OS_DIR)
