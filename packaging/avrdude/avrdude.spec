Summary: TinyOS-specific AVRDUDE
Name: avrdude-tinyos
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
/etc
