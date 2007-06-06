JDK = @JDK@

EXEEXT=

tinyoslibdir=$(libdir)/tinyos

tinyoslib_PROGRAMS = @TOSCOMMLIB@

EXTRA_PROGRAMS = libtoscomm-32.so libtoscomm-64.so toscomm.dll

# Compiling libtoscomm.so with -O2 generates bad code with gcc 4.1.x on x86_64
# (the -O1 code is slightly weird, but works at least ;-))
SOFLAGS = -O1 -shared -fPIC "-I$(JDK)/include" "-I$(JDK)/include/linux"

libtoscomm_32_so_SOURCES = \
  NativeSerialEnums.h \
  NativeSerial_linux.cpp \
  TOSComm_wrap.cxx

libtoscomm_64_so_SOURCES = $(libtoscomm_32_so_SOURCES)

toscomm_dll_SOURCES = \
  NativeSerialEnums.h \
  NativeSerial_win32.cpp \
  TOSComm_wrap.cxx

libtoscomm-32.so: $(libtoscomm_so_SOURCES)
	$(CXX) -m32 $(SOFLAGS) -o $@ NativeSerial_linux.cpp

libtoscomm-64.so: $(libtoscomm_so_SOURCES)
	@echo $(CXX) -m64 $(SOFLAGS) -o $@ NativeSerial_linux.cpp
	@$(CXX) -m64 $(SOFLAGS) -o $@ NativeSerial_linux.cpp || \
	(echo 64-bit libtoscomm.so NOT GENERATED - DO NOT USE THIS RUN TO BUILD AN RPM; echo Press return to continue; read; rm -f libtoscomm-64.so)

toscomm.dll: $(toscomm_dll_SOURCES)
	$(CXX) -O2 -s -mno-cygwin -shared "-I$(JDK)/include" "-I$(JDK)/include/win32" -D_JNI_IMPLEMENTATION -Wl,--kill-at \
	  -o $@ NativeSerial_win32.cpp

