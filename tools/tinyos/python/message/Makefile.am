tospy_PYTHON = __init__.py Message.py MoteIF.py SerialPacket.py

tospydir = $(pythondir)/tinyos/message


SERIAL_H = $(TOSDIR)/lib/serial/Serial.h

SerialPacket.py:
	mig -o $@ -python-classname=SerialPacket python $(SERIAL_H) serial_packet -I$(TOSDIR)/types

