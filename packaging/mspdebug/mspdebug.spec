Summary: TinyOS-specific MSPDebug
Name: mspdebug
Version: %{version}
Release: %{release}
License: GNU GPL
Packager: Eric B. Decker <cire831@gmail.com>
Group: Development/Tools
BuildRoot: %{_builddir}/%{name}-%{version}-%{release}.%{_arch}

%description

%install
rm -rf %{buildroot}
rsync -a %{prefix} %{buildroot}

%files
/usr