Summary: Experimental (4.7) MSP430 gdb
Name: msp430-gdb-47
Version: %{version}
Release: %{release}
License: GNU GPL
Packager: Razvan Musaloiu-E. <razvan@musaloiu.com>
Group: Development/Tools

%description

%install
rsync -a %{prefix} %{buildroot}
(
	cd %{buildroot}/usr
	cat %{prefix}/../../msp430-libc.files | xargs rm -rf
	until find . -empty -exec rm -rf {} \; &> /dev/null
	do : ; done
)

%define __strip /bin/true

%files
/opt/msp430-47
