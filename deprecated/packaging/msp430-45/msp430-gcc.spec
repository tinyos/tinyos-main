Summary: MSP430 (4.5) gcc
Name: msp430-gcc-45
Version: %{version}
Release: %{release}
License: GNU GPL
Packager: Razvan Musaloiu-E. <razvan@musaloiu.com>
Group: Development/Tools
Requires: msp430-binutils-45

%description

%install
rsync -a %{prefix} %{buildroot}
(
	cd %{buildroot}/usr
	cat %{prefix}/../../msp430-binutils.files | xargs rm -rf
	find . -empty | xargs rm -rf
)

%define __strip /bin/true

%files
/opt/msp430-45
