JDK = @JDK@

EXEEXT=

tinyoslibdir=$(libdir)/tinyos

tinyoslib_PROGRAMS = @TOSCOMMLIB@

EXTRA_PROGRAMS = libtoscomm.so toscomm.dll libtoscomm.jnilib

LIBFLAGS = "-I$(JDK)/include" -O2
if !DARWIN
LIBFLAGS += -s
endif

SOFLAGS = $(LIBFLAGS) "-I$(JDK)/include/linux" -shared -fPIC
DLLFLAGS = $(LIBFLAGS) "-I$(JDK)/include/win32" -shared -D_JNI_IMPLEMENTATION -Wl,--kill-at -static-libgcc -static-libstdc++ -fno-rtti
JNILIBFLAGS = $(LIBFLAGS) "-I$(JDK)/Headers" -bundle

libtoscomm_common_SOURCES = \
  NativeSerialEnums.h

#first file should be the main c/cpp file
libtoscomm_so_SOURCES = \
  NativeSerial_linux.cpp \
  $(libtoscomm_common_SOURCES)

toscomm_dll_SOURCES = \
  NativeSerial_win32.cpp \
  $(libtoscomm_common_SOURCES)

libtoscomm_jnilib_SOURCES = \
  NativeSerial_darwin.cpp \
  $(libtoscomm_common_SOURCES)

libtoscomm.jnilib$(EXEEXT): $(libtoscomm_jnilib_SOURCES)
	$(CXX) $(JNILIBFLAGS) $< -o $@

libtoscomm.so$(EXEEXT): $(libtoscomm_so_SOURCES)
	$(CXX) $(SOFLAGS) $< -o $@

toscomm-64.dll$(EXEEXT): $(toscomm_dll_SOURCES)
	$(GCXX64) -m64 $(DLLFLAGS) $< -o $@

toscomm-32.dll$(EXEEXT): $(toscomm_dll_SOURCES)
	$(GCXX32) -m32 $(DLLFLAGS) $< -o $@
