Summary: MSP430 (4.6) headers and linker scripts
Name: msp430mcu-46
Version: %{version}
Release: %{release}
License: GNU GPL
Packager: Razvan Musaloiu-E. <razvan@musaloiu.com>
Group: Development/Tools
BuildRoot: %{_builddir}/%{name}-%{version}-%{release}.%{_arch}

%description

%install
rm -rf %{buildroot}
rsync -a %{prefix} %{buildroot}
(
	cd %{buildroot}/usr
	cat %{prefix}/../../msp430-gcc.files | xargs rm -rf
	until find . -empty -exec rm -rf {} \; &> /dev/null
	do : ; done
)

%files
/usr
