Summary: C library for the AVR platform
Name: avr-libc
Version: %{version}
Release: %{release}
Packager: Andras Biro, Janos Sallai
License: GNU GPL-compatible
Group: Development/Tools
URL: http://www.nongnu.org/avr-libc/
BuildRoot: %{_builddir}/%{name}-%{version}-%{release}.%{_arch}

%description
C library for the AVR platform.

%install
rm -rf %{buildroot}
rsync -a %{sourcedir} %{buildroot}

%files
%defattr(-,root,root)
/


