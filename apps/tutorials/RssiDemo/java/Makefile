all: RssiDemo.class

RssiMsg.class: RssiMsg.java
	javac $<

RssiDemo.class: RssiDemo.java RssiMsg.java
	javac $^

RssiMsg.java: ../RssiDemoMessages.h
	mig java -target=null -java-classname=RssiMsg $< RssiMsg -o $@
