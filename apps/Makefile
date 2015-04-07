#-*-makefile-*-
######################################################################
# 
# Makes the entire suite of TinyOS applications for a given platform.
#
# Author: 	Martin Turon
# Date:		August 18, 2005
#
######################################################################
# $Id: Makefile,v 1.4 2006-12-12 18:22:48 vlahan Exp $

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

BASEDIR = $(shell pwd | sed 's@\(.*\)/apps.*$$@\1@' )
# The output directory for generated documentation
DOCDIR = $(BASEDIR)/doc/nesdoc

PLATFORMS=btnode3 epic eyesIFX eyesIFXv1 eyesIFXv2 intelmote2 iris mica2 mica2dot micaz mulle null sam3s_ek sam3u_ek shimmer shimmer2 shimmer2r span telos telosa telosb tinynode tmote ucbase ucmini ucprotonb z1

nesdoc:
	@echo This target rebuilds documentation for all known platforms.
	@echo It DOES NOT overwrite any existing documentation, thus, it 
	@echo is best run after deleting all old documentation.
	@echo
	@echo To delete all old documentation, delete the contents of the
	@echo $(DOCDIR) directory.
	@echo
	@echo Press Enter to continue, or ^C to abort.
	@read docs
	@echo Building the platformdocumentation.
	for platform in $(PLATFORMS); do \
	  $(MAKE) $$platform docs; \
	done
