COMPONENT=BaseStationC
CFLAGS += -DCC2420_NO_ACKNOWLEDGEMENTS
CFLAGS += -DCC2420_NO_ADDRESS_RECOGNITION

BUILD_EXTRA_DEPS += seriallisten15-4
CLEAN_EXTRA = seriallisten15-4.o seriallisten15-4

seriallisten15-4: seriallisten15-4.o
	gcc -o $@ $< $(TINYOS_OS_DIR)/../support/sdk/c/sf/libmote.a

seriallisten15-4.o: seriallisten15-4.c
	gcc -c -o $@ -I$(TINYOS_OS_DIR)/../support/sdk/c/sf -I$(TINYOS_OS_DIR)/lib/serial -I$(TINYOS_OS_DIR)/types $<

TINYOS_ROOT_DIR?=../..
include $(TINYOS_ROOT_DIR)/Makefile.include
