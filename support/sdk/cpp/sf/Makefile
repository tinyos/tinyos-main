#
# Copyright (c) 2007, Technische Universitaet Berlin
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions 
# are met:
# - Redistributions of source code must retain the above copyright notice,
#   this list of conditions and the following disclaimer.
# - Redistributions in binary form must reproduce the above copyright 
#   notice, this list of conditions and the following disclaimer in the 
#   documentation and/or other materials provided with the distribution.
# - Neither the name of the Technische Universitaet Berlin nor the names 
#   of its contributors may be used to endorse or promote products derived
#   from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
# OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
# OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
# USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#
# @author Philipp Huppertz <huppertz@tkn.tu-berlin.de> 
# @author Andreas Koepke   <koepke@tkn.tu-berlin.de>
#


CC=g++
CFLAGS= -Wall -O3 -pthread

all: sf

sf: sf.o sfcontrol.o serialcomm.o tcpcomm.o basecomm.o packetbuffer.o sfpacket.o
	$(CC) $(CFLAGS) sf.o sfcontrol.o serialcomm.o tcpcomm.o basecomm.o packetbuffer.o sfpacket.o -o sf

%.o: %.cpp
	$(CC) -c $(CFLAGS) $<

serialcomm.o: serialcomm.cpp serialcomm.h basecomm.h sfpacket.h packetbuffer.h sharedinfo.h

tcpcomm.o: tcpcomm.cpp sharedinfo.h tcpcomm.h sfpacket.h packetbuffer.h basecomm.h

sfpacket.o: sfpacket.cpp sfpacket.h serialprotocol.h

basecomm.o: basecomm.cpp basecomm.h 

sfcontrol.o: sfcontrol.cpp sfcontrol.h sharedinfo.h packetbuffer.h tcpcomm.h serialcomm.h

packetbuffer.o: packetbuffer.cpp packetbuffer.h sfpacket.h

clean:
	rm -rf *.o sf

