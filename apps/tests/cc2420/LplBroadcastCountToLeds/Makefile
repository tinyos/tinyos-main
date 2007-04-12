COMPONENT=RadioCountToLedsAppC

CFLAGS += -DACK_LOW_POWER_LISTENING
#CFLAGS += -DNOACK_LOW_POWER_LISTENING

BUILD_EXTRA_DEPS = RadioCountMsg.py RadioCountMsg.class

RadioCountMsg.py: RadioCountToLeds.h
	mig python -target=$(PLATFORM) $(CFLAGS) -python-classname=RadioCountMsg RadioCountToLeds.h radio_count_msg -o $@

RadioCountMsg.class: RadioCountMsg.java
	javac RadioCountMsg.java

RadioCountMsg.java: RadioCountToLeds.h
	mig java -target=$(PLATFORM) $(CFLAGS) -java-classname=RadioCountMsg RadioCountToLeds.h radio_count_msg -o $@


include $(MAKERULES)

