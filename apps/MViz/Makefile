COMPONENT=MVizAppC
CFLAGS += -I$(TINYOS_OS_DIR)/lib/net/ -I$(TINYOS_OS_DIR)/lib/net/ctp -I$(TINYOS_OS_DIR)/lib/net/4bitle -I.
TOSMAKE_PRE_EXE_DEPS = MVizMsg.class

MVizMsg.java: MViz.h
	nescc-mig -I$(TINYOS_OS_DIR)/types -java-classname=MVizMsg java MViz.h mviz_msg -o $@

MVizMsg.class: MVizMsg.java
	javac MVizMsg.java

TINYOS_ROOT_DIR?=../..
include $(TINYOS_ROOT_DIR)/Makefile.include
