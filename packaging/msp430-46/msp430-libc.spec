Summary: MSP430 (4.6) libc
Name: msp430-libc-46
Version: %{version}
Release: %{release}
License: GNU GPL
Packager: Razvan Musaloiu-E. <razvan@musaloiu.com>
Group: Development/Tools
Requires: msp430-binutils-46, msp430-gcc-46

%description

%install
rsync -a %{prefix} %{buildroot}
(
	cd %{buildroot}/usr
	cat %{prefix}/../../msp430mcu.files | xargs rm -rf
	until find . -empty -exec rm -rf {} \; &> /dev/null
	do : ; done
)

%define __strip /bin/true

%files
/usr
