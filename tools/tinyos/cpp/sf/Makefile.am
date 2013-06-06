AUTOMAKE_OPTIONS = foreign

bin_PROGRAMS = sf2
sf2_SOURCES = basecomm.cpp packetbuffer.cpp serialcomm.cpp sfcontrol.cpp \
              sf.cpp sfpacket.cpp  tcpcomm.cpp
noinst_HEADERS = basecomm.h packetbuffer.h serialcomm.h serialprotocol.h \
                 sfcontrol.h sfpacket.h sharedinfo.h tcpcomm.h

sf2_CPPFLAGS = -Wall -O3 -pthread
sf2_LDFLAGS = -pthread
