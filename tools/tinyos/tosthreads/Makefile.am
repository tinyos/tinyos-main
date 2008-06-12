AUTOMAKE_OPTIONS = foreign

dist_man_MANS = tosthreads-dynamic-app.1

tosthreadslibdir=$(libdir)/tinyos/tosthreads

bin_SCRIPTS = tosthreads-dynamic-app

tosthreadslib_DATA = tosthreads_standard_api.py  \
                     tosthreads_tenet_api.py
                     
tosthreads-dynamic-app: tosthreads-dynamic-app.in
	sed -e 's,@tosthreadslibdir\@,$(tosthreadslibdir),g' tosthreads-dynamic-app.in >$@      
	sed -e 's,@pathpython\@,$(pathpython),g' $@ > $@.temp 
	mv $@.temp $@
