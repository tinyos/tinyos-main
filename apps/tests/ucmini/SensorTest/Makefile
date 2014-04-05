COMPONENT=UcminiSensorC

BUILD_EXTRA_DEPS += UcminiSensor.class
CLEAN_EXTRA = *.class UcminiSensorMeas.java

UcminiSensor.class: UcminiSensor.java UcminiSensorMeas.java
	javac UcminiSensor.java

UcminiSensorMeas.java:
	mig java -target=$(PLATFORM) $(CFLAGS) -java-classname=UcminiSensorMeas UcminiSensor.h measurement -o $@


include $(MAKERULES)
