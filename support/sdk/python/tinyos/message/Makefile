SERIAL_H = $(TOSDIR)/lib/serial/Serial.h


SerialPacket.py: 
	mig -o $@ -python-classname=SerialPacket python $(SERIAL_H) serial_packet -I$(TOSDIR)/types
