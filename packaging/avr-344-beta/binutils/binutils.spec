Summary: GNU binutils for the AVR platform
Name: avr-binutils
Version: %{version}
Release: %{release}
Packager: Andras Biro, Janos Sallai
URL: http://ftp.gnu.org/gnu/binutils/
BuildRoot: %{_builddir}/%{name}-%{version}-%{release}.%{_arch}

License: GNU GPL
Group: Development/Tools


%description
The GNU Binutils are a collection of binary tools. The main tools are 
ld and as for the AVR platform. 

%install
rm -rf %{buildroot}
rsync -a %{sourcedir} %{buildroot}

%files
%defattr(-,root,root)
/
