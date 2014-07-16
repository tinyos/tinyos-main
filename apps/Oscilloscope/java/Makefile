GEN=OscilloscopeMsg.java Constants.java

all: oscilloscope.jar

oscilloscope.jar: Oscilloscope.class
	jar cf $@ *.class

OscilloscopeMsg.java: ../Oscilloscope.h
	nescc-mig -java-classname=OscilloscopeMsg java ../Oscilloscope.h oscilloscope -o $@

Constants.java: ../Oscilloscope.h
	nescc-ncg -java-classname=Constants java ../Oscilloscope.h NREADINGS DEFAULT_INTERVAL -o $@

Oscilloscope.class: $(wildcard *.java) $(GEN)
	javac *.java

clean:
	rm -f *.class $(GEN)

veryclean: clean
	rm oscilloscope.jar
