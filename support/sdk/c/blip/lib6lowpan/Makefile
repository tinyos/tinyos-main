
SOURCES=lib6lowpan.c lib6lowpanIP.c  lib6lowpanFrag.c
INCLUDE=../include/

###############
##
## Use these for PC
ifndef GCC
GCC=gcc
endif
ifndef AR
AR=ar
endif

CFLAGS=-DPC -g -I$(INCLUDE)
TEST=testhc.c

###############
##
## These for msp430
# GCC=msp430-gcc
# AR=msp430-ar
# TEST=msp_test.c
# CFLAGS=-DMSP

LIB=lib6lowpan.a
OBJS=$(SOURCES:.c=.o)

$(LIB): $(OBJS)
	$(AR) crv $(LIB) $(OBJS)

test: $(SOURCES) $(TEST) $(LIB)
	$(GCC) -o $@ $(TEST) $(CFLAGS) $(LIB) printpacket.c

%.o: %.c
	$(GCC) -o $@ $< $(CFLAGS) -c

clean:
	rm -f test $(OBJS) $(LIB)

lib6lowpan.o: lib6lowpan.c ip-hdrs
lib6lowpanIP.o: lib6lowpanIP.c ip-hdrs
lib6lowpanFrag.o: lib6lowpanFrag.c ip-hdrs

ip-hdrs: $(INCLUDE)/6lowpan.h $(INCLUDE)/ip.h $(INCLUDE)/lib6lowpan.h