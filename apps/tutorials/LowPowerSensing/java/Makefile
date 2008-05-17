GEN=SerialRequestSamplesMsg.java SerialSampleMsg.java Constants.java

SENSOR_DIR = universal_sensors
#SENSOR_DIR = tmote_onboard_sensors
SENSOR_DEPS = ../$(SENSOR_DIR)/SensorSample.h

all: LowPowerSensingApp.jar

LowPowerSensingApp.jar: LowPowerSensingApp.class
	jar cf $@ *.class

SerialRequestSamplesMsg.java: ../LowPowerSensingMsgs.h $(SENSOR_DEPS)
	mig -I../$(SENSOR_DIR) -target=null \
-java-classname=SerialRequestSamplesMsg java ../LowPowerSensingMsgs.h serial_request_samples_msg -o $@

SerialSampleMsg.java: ../LowPowerSensingMsgs.h $(SENSOR_DEPS)
	mig -I../$(SENSOR_DIR) -target=null \
-java-classname=SerialSampleMsg java ../LowPowerSensingMsgs.h serial_sample_msg -o $@

Constants.java: ../LowPowerSensingConstants.h
	ncg -I../$(SENSOR_DIR) -DLOWPOWERSENSING_JAVA_MAKEFILE -target=null \
-java-classname=Constants java ../LowPowerSensingConstants.h BASE_STATION_ADDR SAMPLING_INTERVAL \
MSG_QUEUE_SIZE LPL_INTERVAL  -o $@

LowPowerSensingApp.class: $(wildcard *.java) $(GEN)
	javac *.java

clean:
	rm -f *.class $(GEN)

veryclean: clean
	rm -f LowPowerSensingApp.jar
