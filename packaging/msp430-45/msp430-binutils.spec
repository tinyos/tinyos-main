Summary: MSP430 (4.5) binutils
Name: msp430-binutils-45
Version: %{version}
Release: %{release}
License: GNU GPL
Packager: Razvan Musaloiu-E. <razvan@musaloiu.com>
Group: Development/Tools

%description

%install
rsync -a %{prefix} %{buildroot}

%files
/opt/msp430-45
