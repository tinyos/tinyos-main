COMPONENT=RadioCountToFlashAppC
BUILD_EXTRA_DEPS = RadioCountMsg.py RadioCountMsg.class

RadioCountMsg.py: RadioCountToFlash.h
	mig python -target=$(PLATFORM) $(CFLAGS) -python-classname=RadioCountMsg RadioCountToFlash.h RadioCountMsg -o $@

RadioCountMsg.class: RadioCountMsg.java
	javac RadioCountMsg.java

RadioCountMsg.java: RadioCountToFlash.h
	mig java -target=$(PLATFORM) $(CFLAGS) -java-classname=RadioCountMsg RadioCountToFlash.h RadioCountMsg -o $@


include $(MAKERULES)

