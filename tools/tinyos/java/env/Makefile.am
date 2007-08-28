JDK = @JDK@

EXEEXT=

tinyoslibdir=$(libdir)/tinyos

tinyoslib_PROGRAMS = @GETENVLIB@

EXTRA_PROGRAMS = libgetenv-32.so libgetenv-64.so getenv.dll libgetenv.jnilib

SOFLAGS = "-I$(JDK)/include/linux" "-I$(JDK)/include" -shared -fpic

libgetenv_32_so_SOURCES = net_tinyos_util_Env.h net_tinyos_util_Env.c
libgetenv_64_so_SOURCES = $(libgetenv_32_so_SOURCES)

libgetenv-32.so : net_tinyos_util_Env.h net_tinyos_util_Env.c
	$(CC) $(SOFLAGS) -m32 net_tinyos_util_Env.c -o$@

libgetenv-64.so : net_tinyos_util_Env.h net_tinyos_util_Env.c
	@echo $(CC) $(SOFLAGS) -m64 net_tinyos_util_Env.c -o$@
	@$(CC) $(SOFLAGS) -m64 net_tinyos_util_Env.c -o$@ || \
	(echo 64-bit libgetenv.so NOT GENERATED - DO NOT USE THIS RUN TO BUILD AN RPM; echo Press return to continue; read; rm -f libtoscomm-64.so)

getenv.dll: net_tinyos_util_Env.h net_tinyos_util_Env.c
	gcc -shared -o$@ -mno-cygwin "-I$(JDK)/include" "-I$(JDK)/include/win32" -D_JNI_IMPLEMENTATION -Wl,--kill-at net_tinyos_util_Env.c

libgetenv.jnilib : net_tinyos_util_Env.h net_tinyos_util_Env.c
	gcc "-I$(JDK)/Headers" -bundle -fPIC net_tinyos_util_Env.c -o $@

