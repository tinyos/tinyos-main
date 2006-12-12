
TestSensor.class: $(wildcard *.java) TestSensorMsg.java
	javac *.java

TestSensorMsg.java:
	mig java -target=null $(CFLAGS) -java-classname=TestSensorMsg TestSensor.h TestSensorMsg -o $@

