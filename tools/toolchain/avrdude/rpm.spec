Summary: avrdude in system programmer for AVR microcontrollers
Name: avrdude-tinyos
Version: PKG_VERSION
Release: PKG_RELEASE
Packager: Andras Biro, Janos Sallai
License: GNU GPL
Group: Development/Tools
# This makes cygwin happy
Provides: /bin/sh /bin/bash

%description
AVRDUDE is an open source utility to download/upload/manipulate the ROM
and EEPROM contents of AVR microcontrollers using the in-system
programming technique (ISP).


%files
%defattr(-,root,root,-)
/etc
/usr

%post
if [ -x /bin/cygwin1.dll ]; then
  uname|grep -q WOW64
  if [ $? -ne 0 ]; then
    pushd /usr/bin
    ./install_giveio.bat
    popd
  else
    echo "Warning: giveio.sys is not working on 64-bit Windows, therefore  parellel port targets won't work"
  fi
fi

%preun
if [ -x /bin/cygwin1.dll ]; then
  uname|grep -q WOW64
  if [ $? -ne 0 ]; then
	pushd /usr/bin
	./remove_giveio.bat
	popd
  fi
fi