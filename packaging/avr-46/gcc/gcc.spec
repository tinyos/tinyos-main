Summary: gcc compiled for the AVR platform with TinyOS patches
Name: avr-gcc
Version: %{version}
Release: %{release}
Packager: Andras Biro, Janos Sallai
URL: ftp://ftp.gnu.org/pub/gnu/
BuildRoot: %{_builddir}/%{name}-%{version}-%{release}.%{_arch}

License: GNU GPL
Group: Development/Tools

%description
gcc compiled for the AVR platform. 

%install
rm -rf %{buildroot}
rsync -a %{sourcedir} %{buildroot}

%files
%defattr(-,root,root)
/