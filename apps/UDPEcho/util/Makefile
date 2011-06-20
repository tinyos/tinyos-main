# -*- makefile -*-

UdpReport.py: ../UDPReport.h
	mig -DMIG -I$(TOSROOT)/tos/lib/net/blip -I$(TOSROOT)/tos/chips/cc2420 -I$(TOSROOT)/support/sdk/c/blip/include  python -python-classname=UdpReport ../UDPReport.h udp_report -o UdpReport.py

