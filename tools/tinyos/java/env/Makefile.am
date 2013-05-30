JDK = @JDK@

EXEEXT=

tinyoslibdir=$(libdir)/tinyos

tinyoslib_PROGRAMS = @GETENVLIB@

EXTRA_PROGRAMS = libgetenv.so getenv.dll libgetenv.jnilib

LIBFLAGS = "-I$(JDK)/include" -s -O2
SOFLAGS = $(LIBFLAGS) "-I$(JDK)/include/linux" -shared -fpic
DLLFLAGS = $(LIBFLAGS) "-I$(JDK)/include/win32" -shared -D_JNI_IMPLEMENTATION -Wl,--kill-at
JNILIBFLAGS = $(LIBFLAGS) "-I$(JDK)/Headers" -bundle -fPIC

#first file should be the main c/cpp file
libgetenv_so_SOURCES = net_tinyos_util_Env.c net_tinyos_util_Env.h

libgetenv.so$(EXEEXT): $(libgetenv_so_SOURCES)
	$(CC) $(SOFLAGS) $< -o $@

getenv-64.dll$(EXEEXT): $(libgetenv_so_SOURCES)
	$(GCC64) -m64 $(DLLFLAGS) $< -o $@

getenv-32.dll$(EXEEXT): $(libgetenv_so_SOURCES)
	$(GCC32) $(DLLFLAGS) $< -o $@

libgetenv.jnilib$(EXEEXT): $(libgetenv_so_SOURCES)
	$(CC) $(JNILIBFLAGS) $< -o $@
