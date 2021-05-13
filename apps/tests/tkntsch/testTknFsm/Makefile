COMPONENT=AppTestTknFsmC

#CFLAGS += -DCC2420_DEF_CHANNEL=$(TOS_CHANNEL)
#CFLAGS += -DJN516_DEF_CHANNEL=$(TOS_CHANNEL)

# disables support for the AM stack, which somewhat reduces code size
# and compresses packet formats.  If you want to use other tinyos
# protocols which are AM-based, you should not include this.
#CFLAGS += -DIEEE154FRAMES_ENABLED

#printf
PFLAGS += -DPRINTFUART_ENABLED
CFLAGS += -I$(TINYOS_OS_DIR)/lib/printf
PFLAGS += -DPRINTF_BUFFER_SIZE=600

PFLAGS += -DTKNFSM_ENABLE_DEBUG_PRINT

TINYOS_ROOT_DIR?=../../../..
include $(TINYOS_ROOT_DIR)/Makefile.include
