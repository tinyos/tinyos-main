COMPONENT=RadioCountToLedsAppC

CFLAGS += -DACK_LOW_POWER_LISTENING

TOSMAKE_PRE_EXE_DEPS = RadioCountMsg.py RadioCountMsg.class
TOSMAKE_CLEAN_EXTRA = *.class *.pyc RadioCountMsg.py RadioCountMsg.java

RadioCountMsg.py: RadioCountToLeds.h
	nescc-mig python $(NESC_PFLAGS) $(CFLAGS) -python-classname=RadioCountMsg RadioCountToLeds.h radio_count_msg -o $@

RadioCountMsg.class: RadioCountMsg.java
	javac RadioCountMsg.java

RadioCountMsg.java: RadioCountToLeds.h
	nescc-mig java $(NESC_PFLAGS) $(CFLAGS) -java-classname=RadioCountMsg RadioCountToLeds.h radio_count_msg -o $@


TINYOS_ROOT_DIR?=../../../..
include $(TINYOS_ROOT_DIR)/Makefile.include
