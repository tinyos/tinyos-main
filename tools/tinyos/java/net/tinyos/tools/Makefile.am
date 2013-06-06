AUTOMAKE_OPTIONS = foreign

INITIAL_TARGETS = PrintfMsg.class PrintfMsg.java

ROOT = ../../..
include $(ROOT)/Makefile.include

PRINTF_H = $(TINYOS_OS_DIR)/lib/printf/printf.h

PrintfMsg.java: $(PRINTF_H)
	mig java $(CFLAGS) -java-classname=net.tinyos.tools.PrintfMsg $(PRINTF_H) printf_msg -o $@ -tosdir=$(TINYOS_OS_DIR)

