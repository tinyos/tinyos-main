COMPONENT=UcminiSensorC

TOSMAKE_PRE_EXE_DEPS += UcminiSensor.class
TOSMAKE_CLEAN_EXTRA = *.class UcminiSensorMeas.java

UcminiSensor.class: UcminiSensor.java UcminiSensorMeas.java
	javac UcminiSensor.java

UcminiSensorMeas.java:
	nescc-mig java $(NESC_PFLAGS) $(CFLAGS) -java-classname=UcminiSensorMeas UcminiSensor.h measurement -o $@


TINYOS_ROOT_DIR?=../../../..
include $(TINYOS_ROOT_DIR)/Makefile.include
