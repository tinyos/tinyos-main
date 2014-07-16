all: RssiDemo.class

RssiMsg.class: RssiMsg.java
	javac $<

RssiDemo.class: RssiDemo.java RssiMsg.java
	javac $^

RssiMsg.java: ../RssiDemoMessages.h
	nescc-mig java -java-classname=RssiMsg $< RssiMsg -o $@

clean:
	rm -f *.class RssiMsg.java
