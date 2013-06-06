GEN=OscilloscopeMsg.java Constants.java

all: oscilloscope.jar

oscilloscope.jar: Oscilloscope.class
	jar cf $@ *.class

OscilloscopeMsg.java: ../MultihopOscilloscope.h
	nescc-mig -java-classname=OscilloscopeMsg java ../MultihopOscilloscope.h oscilloscope -o $@

Constants.java: ../MultihopOscilloscope.h
	nescc-ncg -java-classname=Constants java ../MultihopOscilloscope.h NREADINGS DEFAULT_INTERVAL -o $@

Oscilloscope.class: $(wildcard *.java) $(GEN)
	javac *.java

clean:
	rm -f *.class $(GEN) oscilloscope.jar OscilloscopeMsg.java Constants.java
