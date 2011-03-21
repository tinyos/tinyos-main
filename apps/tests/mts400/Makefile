COMPONENT=Mts400TesterC
SENSORBOARD=mts400

BUILD_EXTRA_DEPS = DataMsg.java Mts400Tester.class
CLEAN_EXTRA = $(BULID_EXTRA_DEPS) *.class

DataMsg.java: DataMsg.h
		mig -target=null -java-classname=DataMsg java DataMsg.h datamsg -o $@
Mts400Tester.class: Mts400Tester.java DataMsg.java
	javac Mts400Tester.java
include $(MAKERULES)
