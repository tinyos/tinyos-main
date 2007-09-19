# $Id: Makefile,v 1.5 2007-09-19 04:39:16 klueska Exp $
#
# TinyOS Tools Makefile
#
# @author  TinyOS Team
#

INITIAL_TARGETS = PrintfMsg.class

ROOT = ../../..
include $(ROOT)/Makefile.include

PRINTF_H = $(TOSDIR)/lib/printf/printf.h

PrintfMsg.java: $(PRINTF_H)
	mig java $(CFLAGS) -java-classname=net.tinyos.tools.PrintfMsg $(PRINTF_H) printf_msg -o $@

