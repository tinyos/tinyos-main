JDK = @JDK@

EXEEXT=

tinyoslibdir=$(libdir)/tinyos

tinyoslib_PROGRAMS = @TOSCOMMLIB@

EXTRA_PROGRAMS = libtoscomm.so toscomm.dll

libtoscomm_so_SOURCES = \
  NativeSerialEnums.h \
  NativeSerial_linux.cpp \
  TOSComm_wrap.cxx

toscomm_dll_SOURCES = \
  NativeSerialEnums.h \
  NativeSerial_win32.cpp \
  TOSComm_wrap.cxx

libtoscomm.so: $(libtoscomm_so_SOURCES)
	$(CXX) -O2 -shared -fPIC "-I$(JDK)/include" "-I$(JDK)/include/linux" \
	  -o $@ NativeSerial_linux.cpp

toscomm.dll: $(toscomm_dll_SOURCES)
	$(CXX) -O2 -s -mno-cygwin -shared "-I$(JDK)/include" "-I$(JDK)/include/win32" -D_JNI_IMPLEMENTATION -Wl,--kill-at \
	  -o $@ NativeSerial_win32.cpp

