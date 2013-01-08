COMPONENT=BaseStationC
#CFLAGS += -DCC2420_NO_ACKNOWLEDGEMENTS
CFLAGS += -DCC2420_HW_ACKNOWLEDGEMENTS
CFLAGS += -DCC2420_NO_ADDRESS_RECOGNITION

BUILD_EXTRA_DEPS += seriallisten15-4
CLEAN_EXTRA = seriallisten15-4.o seriallisten15-4

seriallisten15-4: seriallisten15-4.o
	gcc -o $@ $< $(TOSDIR)/../support/sdk/c/sf/libmote.a -I /usr/msp430/include/ -I /usr/lib/gcc/msp430/4.6.3/include/ -I /usr/include/i386-linux-gnu -I /usr/include/c++/4.6/parallel/ -I /usr/include/i386-linux-gnu/bits/

seriallisten15-4.o: seriallisten15-4.c
	gcc -c -o $@ -I$(TOSDIR)/../support/sdk/c/sf -I$(TOSDIR)/lib/serial -I$(TOSDIR)/types $< -I /usr/msp430/include/ -I /usr/lib/gcc/msp430/4.6.3/include/ -I /usr/include/i386-linux-gnu -I /usr/include/c++/4.6/parallel/ -I /usr/include/i386-linux-gnu/bits/
include $(MAKERULES)
