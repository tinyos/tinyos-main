COMPONENT=RadioSenseToLedsAppC
TOSMAKE_PRE_EXE_DEPS = RadioSenseMsg.py RadioSenseMsg.class

RadioSenseMsg.py: RadioSenseToLeds.h
	nescc-mig python $(NESC_PFLAGS) $(CFLAGS) -python-classname=RadioSenseMsg RadioSenseToLeds.h radio_sense_msg -o $@

RadioSenseMsg.class: RadioSenseMsg.java
	javac RadioSenseMsg.java

RadioSenseMsg.java: RadioSenseToLeds.h
	nescc-mig java $(NESC_PFLAGS) $(CFLAGS) -java-classname=RadioSenseMsg RadioSenseToLeds.h radio_sense_msg -o $@


TINYOS_ROOT_DIR?=../..
include $(TINYOS_ROOT_DIR)/Makefile.include
