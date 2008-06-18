# $Id: Makefile,v 1.6 2008-06-18 19:04:45 sallai Exp $
#
# TinyOS Tools Makefile
#
# @author  TinyOS Team
#

INITIAL_TARGETS = PrintfMsg.class PrintfMsg.java

ROOT = ../../..
include $(ROOT)/Makefile.include

PRINTF_H = $(TOSDIR)/lib/printf/printf.h

PrintfMsg.java: $(PRINTF_H) FORCE
	mig java $(CFLAGS) -java-classname=net.tinyos.tools.PrintfMsg $(PRINTF_H) printf_msg -o $@

