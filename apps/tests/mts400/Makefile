COMPONENT=Mts400TesterC
SENSORBOARD=mts400

BUILD_EXTRA_DEPS = DataMsg.java
CLEAN_EXTRA = $(BULID_EXTRA_DEPS)

DataMsg.java: DataMsg.h
		mig -target=null -java-classname=DataMsg java DataMsg.h datamsg -o $@

include $(MAKERULES)
