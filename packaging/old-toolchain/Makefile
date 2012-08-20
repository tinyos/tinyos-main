SUBDIRS := $(shell find * -maxdepth 0 -type d)
TARGET=$(MAKECMDGOALS)
%:
	@for i in $(SUBDIRS); do \
	  HERE=$$PWD; \
	  if [ -f $$i/Makefile ]; then \
	      cd $$i; \
	      $(MAKE) $(TARGET); \
	      cd $$HERE; \
	  fi; \
	done