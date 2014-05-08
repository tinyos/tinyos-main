AUTOMAKE_OPTIONS = foreign

tinyoslibdir=$(libdir)/tinyos

bin_SCRIPTS = motelist2

tinyoslib_DATA = motelist2_getdevices.py

if CYGWIN
  GETDEVICES_SOURCE = motelist2_getdevices-cygwin.py
else
  GETDEVICES_SOURCE = motelist2_getdevices-linux.py
endif

motelist2_getdevices.py: $(GETDEVICES_SOURCE)
	cp $(GETDEVICES_SOURCE) $@
	
motelist2: motelist2.in
	sed -e 's,@tinyoslibdir\@,$(tinyoslibdir),g' $< | sed -e 's,@pathpython\@,$(pathpython),g' >$@
