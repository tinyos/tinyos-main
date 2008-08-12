# 
# The source must be in a tgz with the 
# name %{target}-%{version}-binutils.tgz.
# When unfolded, the top-level directory 
# must be %{target}-%{version}.
# 
# 03/14/2005 xscale
# target: xscale-elf
# version: 2.15
# release: 1
#
# 03/25/2005 avr
# target: avr
# version: 2.15tinyos
# release: 3
# 

%define target   avr
%define version  2.17tinyos
%define release  3
%define name     %{target}-binutils
%define theprefix /usr
%define source   %{name}-%{version}.tgz

Summary: GNU binutils for the %{target} platform
Name: %{name}
Version: %{version}
Release: %{release}
Packager: kwright, TinyOS Group, UC Berkeley
URL: http://ftp.gnu.org/gnu/binutils/
Source0: %{source}
License: GNU GPL
Group: Development/Tools 
BuildRoot: %{_tmppath}/%{name}-root

%description
The GNU Binutils are a collection of binary tools. The main tools are 
ld and as. This particular collection  contains a patched as for 
use with TinyOS 1.2+ on the %{target} platform. The patch allows 
NesC to use the $ character within symbols to separate component
names and variable names. 

%prep
%setup -q

%build
./configure --target=%{target} --prefix=%{theprefix}
make

%install
rm -rf %{buildroot}%{theprefix}
make prefix=%{buildroot}%{theprefix} install
cd %{buildroot}%{theprefix}
rm -rf info share 
rm lib/libiberty.a

%clean
rm -rf $RPM_BUILD_DIR/%{name}-%{version}
rm -rf $RPM_SOURCE_DIR/%{name}-%{version}

%files
%defattr(-,root,root)
%{theprefix}
%doc

%changelog
* Tue Jul 26 2005 kwright <kwright@cs.berkeley.edu>
- Increase release version for avr; old version did not have the $
  patch
* Tue Mar 11 2005 kwright <kwright@cs.berkeley.edu>
- Initial version for multi-platform, multi-target.


