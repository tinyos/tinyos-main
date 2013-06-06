# -*- makefile -*-

TINYOS_OS_DIR ?= ../../../tos

TFLAGS = -I$(TINYOS_OS_DIR)/lib/net/blip -I$(TINYOS_OS_DIR)/chips/cc2420 -I$(TINYOS_ROOT_DIR)/support/sdk/c/blip/include

UdpReport.py: ../UDPReport.h
	nescc-mig -DMIG $(TFLAGS) python -python-classname=UdpReport ../UDPReport.h udp_report -o UdpReport.py

clean:
	rm -f UdpReport.py
