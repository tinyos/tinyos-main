tospy_PYTHON = __init__.py Message.py MoteIF.py SerialPacket.py

tospydir = $(pythondir)/tinyos/message

TINYOS_OS_DIR ?= ../../../../tos
SERIAL_H = $(TINYOS_OS_DIR)/lib/serial/Serial.h
TFLAGS = -I$(TINYOS_OS_DIR)/lib/serial -I$(TINYOS_OS_DIR)/types

BUILT_SOURCES = SerialPacket.py

SerialPacket.py:
	nescc-mig -o $@ -python-classname=SerialPacket python $(SERIAL_H) serial_packet $(TFLAGS)
