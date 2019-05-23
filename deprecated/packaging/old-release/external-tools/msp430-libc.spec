# 
# The source must be in a tgz with the 
# name %{target}-%{version}-binutils.tgz.
# When unfolded, the top-level directory 
# must be %{target}-%{version}.
# 
# avr:
# target: avr
# libname: libc
# version: 1.2.3
# release: 1
# url: http://savannah.nongnu.org/download/avr-libc/
# 
# xscale-elf:
# target: xscale-elf
# libname: newlib
# version: 1.11tinyos
# release: 1
# url: ftp://sources.redhat.com/pub/newlib/newlib-1.11.0.tar.gz

%define target msp430tools 
%define libname libc
%define version 20080808
%define release 1
%define url http://savannah.nongnu.org/download/
%define name     %{target}-%{libname}
%define theprefix /opt
%define source   %{name}-%{version}.tgz
%define __strip msp430-strip
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
# doconf can have additional configuration parameters
cd src
make

%install
rm -rf %{buildroot}%{theprefix}
cd src
make prefix=%{buildroot}%{theprefix}/msp430 install
cd %{buildroot}%{theprefix}
rm -rf info

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



