COMPONENT=RadioCountToFlashAppC
TOSMAKE_PRE_EXE_DEPS = RadioCountMsg.py RadioCountMsg.class
TOSMAKE_CLEAN_EXTRA = *.class RadioCountMsg.py RadioCountMsg.java

RadioCountMsg.py: RadioCountToFlash.h
	nescc-mig python $(NESC_PFLAGS) $(CFLAGS) -python-classname=RadioCountMsg RadioCountToFlash.h RadioCountMsg -o $@

RadioCountMsg.class: RadioCountMsg.java
	javac RadioCountMsg.java

RadioCountMsg.java: RadioCountToFlash.h
	nescc-mig java $(NESC_PFLAGS)  $(CFLAGS) -java-classname=RadioCountMsg RadioCountToFlash.h RadioCountMsg -o $@


TINYOS_ROOT_DIR?=../../../..
include $(TINYOS_ROOT_DIR)/Makefile.include
