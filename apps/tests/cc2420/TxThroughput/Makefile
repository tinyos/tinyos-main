COMPONENT=TxThroughputC
TOSMAKE_PRE_EXE_DEPS = ThroughputMsg.py ThroughputMsg.java ThroughputMsg.class
TOSMAKE_CLEAN_EXTRA = *.class *.pyc ThroughputMsg.py ThroughputMsg.java

ThroughputMsg.py: TxThroughput.h
	nescc-mig python $(NESC_PFLAGS) $(CFLAGS) -python-classname=ThroughputMsg TxThroughput.h ThroughputMsg -o $@

ThroughputMsg.java: TxThroughput.h
	nescc-mig java $(NESC_PFLAGS) $(CFLAGS) -java-classname=ThroughputMsg TxThroughput.h ThroughputMsg -o $@

ThroughputMsg.class: $(wildcard *.java) ThroughputMsg.java
	javac *.java

TINYOS_ROOT_DIR?=../../../..
include $(TINYOS_ROOT_DIR)/Makefile.include
