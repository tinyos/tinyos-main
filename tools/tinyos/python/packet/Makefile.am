tospy_PYTHON = avrmote.py SerialIO.py SFProtocol.py __init__.py \
			   PacketDispatcher.py  SerialProtocol.py  SFSource.py \
IO.py        PacketSource.py      Serial.py          SocketIO.py \
Makefile     Platform.py          SerialSource.py    ThreadTask.py

tospydir = $(pythondir)/tinyos/packet


# Makefile for tools/java/net/tinyos/packet

SERIAL_H = $(TINYOS_OS_DIR)/lib/serial/Serial.h

Serial.py:
	ncg -o $@ -python-classname=Serial python $(SERIAL_H) Serial.h

