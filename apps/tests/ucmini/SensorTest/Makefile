COMPONENT=UcminiSensorC

BUILD_EXTRA_DEPS += UcminiSensor.class
CLEAN_EXTRA = *.class UcminiSensorMeas.java UcminiSensorCalib.java

UcminiSensor.class: UcminiSensor.java UcminiSensorCalib.java UcminiSensorMeas.java
	javac UcminiSensor.java

UcminiSensorMeas.java:
	mig java -target=$(PLATFORM) $(CFLAGS) -java-classname=UcminiSensorMeas UcminiSensor.h measurement -o $@

UcminiSensorCalib.java:
	mig java -target=$(PLATFORM) $(CFLAGS) -java-classname=UcminiSensorCalib UcminiSensor.h calib -o $@

include $(MAKERULES)
