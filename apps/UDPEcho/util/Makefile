# -*- makefile -*-

UdpReport.py: ../UDPReport.h
	mig -DMIG -I$(TINYOS_OS_DIR)/lib/net/blip -I$(TINYOS_OS_DIR)/chips/cc2420 -I$(TINYOS_ROOT_DIR)/support/sdk/c/blip/include  python -python-classname=UdpReport ../UDPReport.h udp_report -o UdpReport.py

