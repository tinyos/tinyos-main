COMPONENT=TestTimeStampingC
CFLAGS += -DTOSH_DATA_LENGTH=39

TOSMAKE_PRE_EXE_DEPS = Analize.class TestMsg.class LinearEquations.class
TOSMAKE_CLEAN_EXTRA = TestMsg.class TestMsg.java \
	Analize.class Analize\$$Entry.class \
	LinearEquations.class LinearEquations\$$Solution.class LinearEquations\$$Equation.class

%.class : %.java TestMsg.java
	if cygpath -w / >/dev/null 2>/dev/null; \
	then CLASSPATH="$$CLASSPATH;Jama-1.0.2.jar" javac $<; \
	else CLASSPATH="$$CLASSPATH:Jama-1.0.2.jar" javac $<; fi

TestMsg.java: TestTimeStamping.h Makefile
	nescc-mig java $(NESC_PFLAGS) $(CFLAGS) -java-classname=TestMsg TestTimeStamping.h test_msg_t -o $@

TINYOS_ROOT_DIR?=../../../..
include $(TINYOS_ROOT_DIR)/Makefile.include
