Summary: avrdude in system programmer for AVR microcontrollers
Name: avrdude-tinyos
Version: PKG_VERSION
Release: PKG_RELEASE
Packager: Andras Biro, Janos Sallai

License: GNU GPL
Group: Development/Tools

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
  pushd /usr/bin
  ./install_giveio.bat
  popd
fi

%preun
if [ -x /bin/cygwin1.dll ]; then
  pushd /usr/bin
  ./remove_giveio.bat
  popd
fi