Summary: Experimental (4.7) MSP430 gccn
Name: msp430-gcc-47
Version: %{version}
Release: %{release}
License: GNU GPL
Packager: Razvan Musaloiu-E. <razvan@musaloiu.com>
Group: Development/Tools
Requires: msp430-binutils-47
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
/opt/msp430-47
