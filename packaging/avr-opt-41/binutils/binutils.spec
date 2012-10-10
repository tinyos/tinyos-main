Summary: GNU binutils for the AVR platform
Name: avr-binutils-tinyos-41
Version: %{version}
Release: %{release}
Packager: Andras Biro, Janos Sallai
URL: http://ftp.gnu.org/gnu/binutils/binutils-2.17.tar.bz2

License: GNU GPL
Group: Development/Tools


%description
The GNU Binutils are a collection of binary tools. The main tools are 
ld and as for the AVR platform. 

%install
rsync -a %{sourcedir} %{buildroot}

%files
%defattr(-,root,root)
/
