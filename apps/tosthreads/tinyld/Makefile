#-*-makefile-*-
######################################################################
# 
# Makes the entire suite of TinyOS applications for a given platform.
#
# Author: 	Martin Turon
# Date:		August 18, 2005
#
######################################################################
# $Id: Makefile,v 1.1 2009-12-23 18:08:47 klueska Exp $

# MAKECMDGOALS is the way to get the arguments passed into a Makefile ...
TARGET=$(MAKECMDGOALS)
NESDOC_TARGET=$(filter-out nesdoc,$(TARGET))

# Here is a way to get the list of subdirectories in a Makefile ...
ROOT=.
SUBDIRS := $(shell find * -type d)

# Okay, match any target, and recurse the subdirectories
%: 
	@for i in $(SUBDIRS); do \
	  HERE=$$PWD; \
	  if [ -f $$i/Makefile ]; then \
	      echo Building ... $(PWD)/$$i; \
	      echo make $(TARGET); \
	      cd $$i; \
	      $(MAKE) $(TARGET); \
	      cd $$HERE; \
	  fi; \
	done

threads:
	@:
cthreads:
	@:
dynthreads:
	@:

BASEDIR = $(shell pwd | sed 's@\(.*\)/apps.*$$@\1@' )
# The output directory for generated documentation
DOCDIR = $(BASEDIR)/doc/nesdoc

nesdoc:
	@echo This target rebuilds documentation for all known platforms.
	@echo It DOES NOT overwrite any existing documentation, thus, it 
	@echo is best run after deleting all old documentation.
	@echo
	@echo To delete all old documentation, delete the contents of the
	@echo $(DOCDIR) directory.
	@echo
	@echo Press Enter to continue, or ^C to abort.
	@read
	for platform in `ncc -print-platforms`; do \
	  $(MAKE) $$platform docs.nohtml.preserve; \
	  nesdoc -o $(DOCDIR) -html -target=$$platform; \
	done
