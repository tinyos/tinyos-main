COMPONENT=TestTimeStampingC
CFLAGS += -DTOSH_DATA_LENGTH=39

BUILD_EXTRA_DEPS = Analize.class TestMsg.class LinearEquations.class
CLEAN_EXTRA = TestMsg.class TestMsg.java \
	Analize.class Analize\$$Entry.class \
	LinearEquations.class LinearEquations\$$Solution.class LinearEquations\$$Equation.class

%.class : %.java TestMsg.java
	if cygpath -w / >/dev/null 2>/dev/null; \
	then CLASSPATH="$$CLASSPATH;Jama-1.0.2.jar" javac $<; \
	else CLASSPATH="$$CLASSPATH:Jama-1.0.2.jar" javac $<; fi 

TestMsg.java: TestTimeStamping.h Makefile
	mig java -target=$(PLATFORM) $(CFLAGS) -java-classname=TestMsg TestTimeStamping.h test_msg_t -o $@

include $(MAKERULES)
