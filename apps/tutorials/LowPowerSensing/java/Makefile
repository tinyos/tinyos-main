GEN=SerialRequestSamplesMsg.java SerialSampleMsg.java Constants.java

SENSOR_DIR = universal_sensors
SENSOR_DEPS = ../$(SENSOR_DIR)/SensorSample.h

TFLAGS = -I../$(SENSOR_DIR) -I$(TINYOS_OS_DIR)/types -I$(TINYOS_OS_DIR)/platforms/null -I$(TINYOS_OS_DIR)/lib/serial

TINYOS_OS_DIR ?= ../../../../tos

all: LowPowerSensingApp.jar

LowPowerSensingApp.jar: LowPowerSensingApp.class
	jar cf $@ *.class

SerialRequestSamplesMsg.java: ../LowPowerSensingMsgs.h $(SENSOR_DEPS)
	nescc-mig $(TFLAGS) \
		-java-classname=SerialRequestSamplesMsg java ../LowPowerSensingMsgs.h serial_request_samples_msg -o $@

SerialSampleMsg.java: ../LowPowerSensingMsgs.h $(SENSOR_DEPS)
	nescc-mig $(TFLAGS) \
		-java-classname=SerialSampleMsg java ../LowPowerSensingMsgs.h serial_sample_msg -o $@

Constants.java: ../LowPowerSensingConstants.h
	nescc-ncg $(TFLAGS) -DLOWPOWERSENSING_JAVA_MAKEFILE \
		-java-classname=Constants java ../LowPowerSensingConstants.h BASE_STATION_ADDR SAMPLING_INTERVAL \
		MSG_QUEUE_SIZE LPL_INTERVAL  -o $@

LowPowerSensingApp.class: $(wildcard *.java) $(GEN)
	javac *.java

clean:
	rm -f *.class $(GEN) LowPowerSensingApp.jar Constants.java SerialSampleMsg.java SerialRequestSamplesMsg.java
