Summary: TinyOS-specific MSP430 gcc
Name: msp430-gcc-tinyos-legacy
Version: %{version}
Release: %{release}
License: GNU GPL
Packager: Razvan Musaloiu-E. <razvan@musaloiu.com>
Group: Development/Tools
Requires: msp430-binutils-tinyos-legacy
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
