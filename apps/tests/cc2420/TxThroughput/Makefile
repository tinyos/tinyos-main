COMPONENT=TxThroughputC
BUILD_EXTRA_DEPS = ThroughputMsg.py ThroughputMsg.java ThroughputMsg.class
CLEAN_EXTRA = *.class *.pyc ThroughputMsg.py ThroughputMsg.java

ThroughputMsg.py: TxThroughput.h
	mig python -target=$(PLATFORM) $(CFLAGS) -python-classname=ThroughputMsg TxThroughput.h ThroughputMsg -o $@

ThroughputMsg.java: TxThroughput.h
	mig java -target=$(PLATFORM) $(CFLAGS) -java-classname=ThroughputMsg TxThroughput.h ThroughputMsg -o $@

ThroughputMsg.class: $(wildcard *.java) ThroughputMsg.java
	javac *.java

include $(MAKERULES)


 
