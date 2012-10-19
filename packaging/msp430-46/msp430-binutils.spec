Summary: MSP430 (4.6) binutils
Name: msp430-binutils-46
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
