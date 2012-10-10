Summary: TinyOS-specific MSP430 libc
Name: msp430-libc-tinyos-legacy
Version: %{version}
Release: %{release}
License: GNU GPL
Packager: Razvan Musaloiu-E. <razvan@musaloiu.com>
Group: Development/Tools
Requires: msp430-binutils-tinyos-legacy, msp430-gcc-tinyos

%description

%install
rsync -a %{prefix} %{buildroot}
(
	cd %{buildroot}/usr
	cat %{prefix}/../../msp430-gcc.files | xargs rm -rf
	until find . -empty -exec rm -rf {} \; &> /dev/null
	do : ; done
)

%define __strip /bin/true

%files
/usr
