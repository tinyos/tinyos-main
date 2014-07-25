AUTOMAKE_OPTIONS = foreign

SUBDIRS = net

JAVADOCDIR = ../../../doc/javadoc

ROOT = .
include $(ROOT)/Makefile.include

tinyosjardir = $(JAR_DIR)
tinyosjar_DATA = tinyos.jar

all: tinyos.jar

tinyos.jar:
	rm -f tinyos.jar
	@# create the jar, as update requires it to exist. we use a
	@# .class file we assume always exists
	find . | grep -E "class|jpg|gif|lib" | xargs jar cf tinyos.jar


javadoc:
	rm -rf $(JAVADOCDIR)
	mkdir -p $(JAVADOCDIR)
	javadoc -d $(JAVADOCDIR) `find -name *.java`
