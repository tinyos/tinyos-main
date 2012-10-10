Summary: TinyOS-specific MSP430 binutils
Name: msp430-binutils-tinyos-legacy
Version: %{version}
Release: %{release}
License: GNU GPL
Packager: Razvan Musaloiu-E. <razvan@musaloiu.com>
Group: Development/Tools

%description

%install
rsync -a %{prefix} %{buildroot}

%files
/usr
