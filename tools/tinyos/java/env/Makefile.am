JDK = @JDK@

EXEEXT=

tinyoslibdir=$(libdir)/tinyos

tinyoslib_PROGRAMS = @GETENVLIB@

EXTRA_PROGRAMS = libgetenv-32.so libgetenv-64.so getenv.dll libgetenv.jnilib

LIBFLAGS = "-I$(JDK)/include" -s -shared -O2
SOFLAGS = $(LIBFLAGS) "-I$(JDK)/include/linux" -fpic
DLLFLAGS = $(LIBFLAGS) "-I$(JDK)/include/win32" -D_JNI_IMPLEMENTATION -Wl,--kill-at -mno-cygwin
JNILABFLAGS = $(LIBFLAGS) "-I$(JDK)/Headers" -bundle -fPIC

#first file should be the main c/cpp file
libgetenv_SOURCES = net_tinyos_util_Env.c net_tinyos_util_Env.h

libgetenv-32.so : $(libgetenv_SOURCES)
$(CC) -m32 $(SOFLAGS) $< -o $@|| \
(echo 32-bit libgetenv.so NOT GENERATED; rm -f $@)

libgetenv-64.so : $(libgetenv_SOURCES)
$(CC) -m64 $(SOFLAGS) $< -o $@|| \
(echo 64-bit libgetenv.so NOT GENERATED; rm -f $@)

getenv.dll: $(libgetenv_SOURCES)
$(CC) $(DLLFLAGS) $< -o $@

libgetenv.jnilib : $(libgetenv_SOURCES)
$(CC) $(JNILIBFLAGS) $< -o $@