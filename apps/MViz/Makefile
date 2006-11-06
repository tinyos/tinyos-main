COMPONENT=MVizAppC
CFLAGS += -I$(TOSDIR)/lib/net/ -I$(TOSDIR)/lib/net/ctp -I$(TOSDIR)/lib/net/le -I.
BUILD_EXTRA_DEPS = MVizMsg.class

MVizMsg.java: MViz.h
	mig -target=null -java-classname=MVizMsg java MViz.h mviz_msg -o $@

MVizMsg.class: MVizMsg.java
	javac MVizMsg.java

include $(MAKERULES)
