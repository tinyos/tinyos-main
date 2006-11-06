COMPONENT=TestPrintfAppC
CFLAGS += -I$(TOSDIR)/lib/printf

BUILD_EXTRA_DEPS += PrintfMsg.class PrintfClient.class

%.class: %.java
	javac $<

PrintfMsg.java: $(TOSDIR)/lib/printf/printf.h
	mig java -target=$(PLATFORM) $(CFLAGS) -java-classname=PrintfMsg $(TOSDIR)/lib/printf/printf.h PrintfMsg -o $@

include $(MAKERULES)

