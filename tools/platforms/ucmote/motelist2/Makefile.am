AUTOMAKE_OPTIONS = foreign

bin_SCRIPTS = motelist2

if CYGWIN
  GETDEVICES_SOURCE = tosdevicesearch-cygwin.py
else
  GETDEVICES_SOURCE = tosdevicesearch-linux.py
endif

tospy_PYTHON = tosdevicesearch.py
tospydir = $(pythondir)/tinyos

tospy3_PYTHON = tosdevicesearch.py
tospy3dir = $(pythondir3)/tinyos

tosdevicesearch.py: $(GETDEVICES_SOURCE)
	cp $(GETDEVICES_SOURCE) $@