Summary: C library for the AVR platform
Name: avr-libc-tinyos-46
Version: %{version}
Release: %{release}
Packager: Andras Biro, Janos Sallai
License: GNU GPL-compatible
Group: Development/Tools
URL: http://www.nongnu.org/avr-libc/3/

%description
C library for the AVR platform.

%install
rsync -a %{sourcedir} %{buildroot}

%files
%defattr(-,root,root)
/


