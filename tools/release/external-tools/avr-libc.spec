# 
# The source must be in a tgz with the 
# name %{target}-%{version}-binutils.tgz.
# When unfolded, the top-level directory 
# must be %{target}-%{version}.
# 

%define target avr
%define libname libc
%define version 1.4.7
%define release 1
%define url http://savannah.nongnu.org/download/
%define name     %{target}-%{libname}
%define theprefix /usr
%define source   %{name}-%{version}.tgz
%define __strip avr-strip
%define debug_package %{nil}

Summary: C library for the %{target} platform
Name: %{name}
Version: %{version}
Release: %{release}
Packager: TinyOS Group, UC Berkeley
License: GNU GPL-compatible
Group: Development/Tools
URL: %{url}
Source0: %{source}
BuildRoot: %{_tmppath}/%{name}-root

%description
C library for the %{target} platform.

%prep
%setup -q

%build
./configure --prefix=%{theprefix}  --build=`./config.guess` --host=avr
make

%install
rm -rf %{buildroot}%{theprefix}
make prefix=%{buildroot}%{theprefix} install

%clean
rm -rf $RPM_BUILD_DIR/%{name}-%{version}
rm -rf $RPM_SOURCE_DIR/%{name}-%{version}

%files
%{theprefix}
%defattr(-,root,root,-)
%doc


%changelog
* Fri Mar 10 2005 root <kwright@cs.berkeley.edu> 1.2.3-1
- Initial version for multi-platform, multi-target



