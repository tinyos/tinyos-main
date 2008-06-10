COMPONENT=BaseStationC
CFLAGS += -DCC2420_NO_ACKNOWLEDGEMENTS
CFLAGS += -DCC2420_NO_ADDRESS_RECOGNITION

BUILD_EXTRA_DEPS += seriallisten15-4
CLEAN_EXTRA = seriallisten15-4.o seriallisten15-4

seriallisten15-4: seriallisten15-4.o
	gcc -o $@ $< $(TOSDIR)/../support/sdk/c/sf/libmote.a

seriallisten15-4.o: seriallisten15-4.c
	gcc -c -o $@ -I$(TOSDIR)/../support/sdk/c/sf -I$(TOSDIR)/lib/serial -I$(TOSDIR)/types $<

include $(MAKERULES)
