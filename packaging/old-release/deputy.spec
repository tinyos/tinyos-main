%define deputy_name deputy
%define tinyos_deputy_version 1.1
%define tinyos_deputy_release 1

Summary: Deputy compiler for Safe TinyOS.
Name: tinyos-%{deputy_name}
Version: %{tinyos_deputy_version}
Release: %{tinyos_deputy_release}%{dist}
Source: http://deputy.cs.berkeley.edu/%{name}-%{tinyos_deputy_version}-%{tinyos_deputy_release}.tar.gz
Patch0: tinyos-%{deputy_name}-%{tinyos_deputy_version}-%{tinyos_deputy_release}.patch
Vendor: Deputy
URL: http://deputy.cs.berkeley.edu/
License: LGPL
Group: Developement tool
BuildRoot: %{_tmppath}/%{name}-root

%description
This package is the deputy compiler for Safe TinyOS.

%prep
%setup -q
%patch0 -p0

%build
touch configure
./configure --prefix=/usr
make

%install
rm -rf $RPM_BUILD_ROOT
make DESTDIR=$RPM_BUILD_ROOT install
rm -rf $RPM_BUILD_ROOT/usr/lib/deputy/bin/deputy.byte.exe

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
/usr/bin/*
/usr/lib/*
/usr/man/man1/*


%changelog
