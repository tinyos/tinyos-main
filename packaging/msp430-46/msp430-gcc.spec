Summary: MSP430 (4.6) gcc
Name: msp430-gcc-46
Version: %{version}
Release: %{release}
License: GNU GPL
Packager: Razvan Musaloiu-E. <razvan@musaloiu.com>
Group: Development/Tools
Requires: msp430-binutils-46
BuildRoot: %{_builddir}/%{name}-%{version}-%{release}.%{_arch}

%description

%install
rm -rf %{buildroot}
rsync -a %{prefix} %{buildroot}
(
	cd %{buildroot}/usr
	cat %{prefix}/../../msp430-binutils.files | xargs rm -rf
	find . -empty | xargs rm -rf
)

%define __strip /bin/true

%files
/usr
