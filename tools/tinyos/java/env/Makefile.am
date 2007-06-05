JDK = @JDK@

EXEEXT=

tinyoslibdir=$(libdir)/tinyos

tinyoslib_PROGRAMS = @GETENVLIB@

EXTRA_PROGRAMS = libgetenv.so getenv.dll

libgetenv_so_SOURCES = net_tinyos_util_Env.h net_tinyos_util_Env.c

libgetenv.so : net_tinyos_util_Env.h net_tinyos_util_Env.c
	gcc "-I$(JDK)/include/linux" "-I$(JDK)/include" -shared -fpic -m32 net_tinyos_util_Env.c -o$@

getenv.dll: net_tinyos_util_Env.h net_tinyos_util_Env.c
	gcc -shared -o$@ -mno-cygwin "-I$(JDK)/include" "-I$(JDK)/include/win32" -D_JNI_IMPLEMENTATION -Wl,--kill-at net_tinyos_util_Env.c
