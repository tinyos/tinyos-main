Summary: TinyOS-specific AVRDUDE
Name: avrdude-tinyos-beta
Version: %{version}
Release: %{release}
License: GNU GPL
Packager: Razvan Musaloiu-E. <razvan@musaloiu.com>
Group: Development/Tools

%description

%install
rsync -a %{sourcedir} %{buildroot}

%files
%defattr(-,root,root)
/usr
/etc
