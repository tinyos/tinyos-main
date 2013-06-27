Summary: gcc compiled for the AVR platform with TinyOS patches
Name: avr-gcc-tinyos-41
Version: %{version}
Release: %{release}
Packager: Andras Biro, Janos Sallai
URL: ftp://ftp.gnu.org/pub/gnu/gcc/gcc-4.1.2/gcc-core-4.1.2.tar.bz2

License: GNU GPL
Group: Development/Tools

%description
gcc compiled for the AVR platform. 

%install
rsync -a %{sourcedir} %{buildroot}

%files
%defattr(-,root,root)
/