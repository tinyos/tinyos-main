COMPONENT=Mts400TesterC

BUILD_EXTRA_DEPS = DataMsg.java Mts400Tester.class
CLEAN_EXTRA = $(BULID_EXTRA_DEPS) *.class

DataMsg.java: DataMsg.h
	nescc-mig -java-classname=DataMsg java DataMsg.h datamsg -o $@
Mts400Tester.class: Mts400Tester.java DataMsg.java
	javac Mts400Tester.java
TINYOS_ROOT_DIR?=../../..
include $(TINYOS_ROOT_DIR)/Makefile.include
$(call TOSMake_include_sensor,mts400)
