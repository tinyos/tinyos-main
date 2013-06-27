Summary: TinyOS-specific MSPDebug
Name: mspdebug
Version: %{version}
Release: %{release}
License: GNU GPL
Packager: Eric B. Decker <cire831@gmail.com>
Group: Development/Tools

%description

%install
rsync -a %{prefix} %{buildroot}

%files
/usr