GEN=SettingsMsg.java AlertMsg.java Constants.java

ANTITHEFT_H=../Nodes/antitheft.h

all: antitheft.jar

antitheft.jar: AntiTheftGui.class
	jar cf $@ *.class

SettingsMsg.java: $(ANTITHEFT_H)
	nescc-mig -java-classname=SettingsMsg java $(ANTITHEFT_H) settings -o $@

AlertMsg.java: $(ANTITHEFT_H)
	nescc-mig -java-classname=AlertMsg java $(ANTITHEFT_H) alert -o $@

Constants.java: $(ANTITHEFT_H)
	nescc-ncg -java-classname=Constants java $(ANTITHEFT_H) antitheft.h -o $@

AntiTheftGui.class: $(wildcard *.java) $(GEN)
	javac *.java

clean:
	rm -f *.class $(GEN)

veryclean: clean
	rm antitheft.jar
