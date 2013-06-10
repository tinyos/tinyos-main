COMPONENT=RadioCountToLedsAppC
TOSMAKE_PRE_EXE_DEPS = RadioCountMsg.py RadioCountMsg.class
TOSMAKE_CLEAN_EXTRA = RadioCountMsg.py RadioCountMsg.class RadioCountMsg.java

RadioCountMsg.py: RadioCountToLeds.h
	nescc-mig python $(CFLAGS) $(NESC_PFLAGS) -python-classname=RadioCountMsg RadioCountToLeds.h radio_count_msg -o $@

RadioCountMsg.class: RadioCountMsg.java
	javac RadioCountMsg.java

RadioCountMsg.java: RadioCountToLeds.h
	nescc-mig java $(CFLAGS) $(NESC_PFLAGS) -java-classname=RadioCountMsg RadioCountToLeds.h radio_count_msg -o $@


TINYOS_ROOT_DIR?=../..
include $(TINYOS_ROOT_DIR)/Makefile.include

