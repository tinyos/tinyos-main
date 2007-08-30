# Top-level Makefile for tools/java

SUBDIRS = net

JAVADOCDIR = ../../../doc/html/javadoc

ROOT = .
include $(ROOT)/Makefile.include

tinyos.jar: all
	rm -f tinyos.jar
	@# create the jar, as update requires it to exist. we use a
	@# .class file we assume always exists
	find . | grep -E "class|jpg|gif" | xargs jar cf tinyos.jar


javadoc: all
	rm -rf $(JAVADOCDIR)
	mkdir -p $(JAVADOCDIR)
	javadoc -d $(JAVADOCDIR) `find -name *.java`
