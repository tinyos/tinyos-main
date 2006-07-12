# Top-level Makefile for tools/java 

# We do all subdirectories (to allow for optional package installation)
SUBDIRS = packet message sf $(shell find . -maxdepth 1 -type d | tail -n +2 | grep -v /CVS | grep -v packet | grep -v message | grep -v sf)

ROOT = ../..
include $(ROOT)/Makefile.include
