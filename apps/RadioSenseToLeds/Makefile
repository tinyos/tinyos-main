COMPONENT=RadioSenseToLedsAppC
BUILD_EXTRA_DEPS = RadioSenseMsg.py RadioSenseMsg.class

RadioSenseMsg.py: RadioSenseToLeds.h
	mig python -target=$(PLATFORM) $(CFLAGS) -python-classname=RadioSenseMsg RadioSenseToLeds.h radio_sense_msg -o $@

RadioSenseMsg.class: RadioSenseMsg.java
	javac RadioSenseMsg.java

RadioSenseMsg.java: RadioSenseToLeds.h
	mig java -target=$(PLATFORM) $(CFLAGS) -java-classname=RadioSenseMsg RadioSenseToLeds.h radio_sense_msg -o $@


include $(MAKERULES)

