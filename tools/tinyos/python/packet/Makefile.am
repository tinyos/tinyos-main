tospy_PYTHON = avrmote.py SerialIO.py SFProtocol.py __init__.py \
               PacketDispatcher.py SerialProtocol.py SFSource.py IO.py \
               PacketSource.py SerialH.py SocketIO.py Platform.py \
               SerialSource.py ThreadTask.py

tospydir = $(pythondir)/tinyos/packet
BUILT_SOURCES = SerialH.py

SERIAL_H = $(TINYOS_OS_DIR)/lib/serial/Serial.h
TINYOS_OS_DIR ?= ../../../../tos
TFLAGS = -I$(TINYOS_OS_DIR)/lib/serial -I$(TINYOS_OS_DIR)/types

SerialH.py:
	nescc-ncg -o $@ $(TFLAGS) -python-classname=Serial python $(SERIAL_H) Serial.h
