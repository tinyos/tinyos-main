# Makefile for tools/java/net/tinyos/packet

SERIAL_H = $(TOSDIR)/lib/serial/Serial.h

Serial.py:  
	ncg -o $@ -python-classname=Serial python $(SERIAL_H) Serial.h
