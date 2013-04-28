JDK = @JDK@

EXEEXT=

tinyoslibdir=$(libdir)/tinyos

tinyoslib_PROGRAMS = @GETENVLIB@

EXTRA_PROGRAMS = libgetenv.so getenv.dll libgetenv.jnilib

LIBFLAGS = "-I$(JDK)/include" -s -shared -O2
SOFLAGS = $(LIBFLAGS) "-I$(JDK)/include/linux" -fpic
DLLFLAGS = $(LIBFLAGS) "-I$(JDK)/include/win32" -D_JNI_IMPLEMENTATION -Wl,--kill-at -mno-cygwin
JNILABFLAGS = $(LIBFLAGS) "-I$(JDK)/Headers" -bundle -fPIC

#first file should be the main c/cpp file
libgetenv_so_SOURCES = net_tinyos_util_Env.c net_tinyos_util_Env.h

libgetenv.so : $(libgetenv_so_SOURCES)
	$(CC) $(SOFLAGS) $< -o $@

getenv.dll: $(libgetenv_so_SOURCES)
	$(CC) $(DLLFLAGS) $< -o $@

libgetenv.jnilib : $(libgetenv_so_SOURCES)
	$(CC) $(JNILIBFLAGS) $< -o $@