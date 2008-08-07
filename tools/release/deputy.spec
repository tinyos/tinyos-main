%define name deputy
%define version 1.1
%define release 1

Summary: Deputy compiler for Safe TinyOS.
Name: %{name}
Version: %{version}
Release: %{release}%{?dist}
Source: http://deputy.cs.berkeley.edu/deputy-1.1.tar.gz
Patch0: deputy.patch
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
