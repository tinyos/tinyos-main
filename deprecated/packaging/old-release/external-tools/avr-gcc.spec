# 
# The source must be in a tgz with the 
# name %{target}-%{version}-binutils.tgz.
# When unfolded, the top-level directory 
# must be %{target}-%{version}.
# 
#
# 03/14/2005 xscale
# target: xscale-elf
# version: 3.4.3
# release: 1
# 

%define target avr 
%define version  4.1.2
%define release  1
%define name     %{target}-gcc
%define theprefix /usr
%define source %{name}-%{version}.tgz
%define __strip avr-strip

Summary: gcc compiled for the %{target} platform 
Name: %{name}
Version: %{version}
Release: %{release}
Packager: kwright, TinyOS Group, UC Berkeley
License: GNU GPL
Group: Development/Tools
URL: ftp://ftp.gnu.org/pub/gnu/gcc/gcc-3.4.3/gcc-3.4.3.tar.bz2
Source0: %{name}-%{version}.tgz
BuildRoot: %{_tmppath}/%{name}-root

%description
gcc compiled for the %{target} platform. The tarfile was renamed 
to %{target}-gcc* to reflect the purpose. 

%prep
%setup -q

%build
./configure --target=%{target} --enable-languages=c --disable-nls --prefix=/usr --disable-libssp
make

%install
rm -rf %{buildroot}%{theprefix}
make prefix=%{buildroot}%{theprefix} install
cd %{buildroot}%{theprefix}
rm lib/libiberty.a
sed -i -e "s|%{buildroot}||g" lib/gcc/avr/*/install-tools/mkheaders.conf

%clean
rm -rf $RPM_BUILD_DIR/%{name}-%{version}
rm -rf $RPM_SOURCE_DIR/%{name}-%{version}

%files
%defattr(-,root,root,-)
%{theprefix}
%doc

%changelog
* Sun Aug 10 2008 pal <pal@cs.stanford.edu> 4.1.2, avr
* Mon Mar 14 2005 root <kwright@cs.berkeley.edu> 3.4.3
- Initial build for multi-platform, multi-target


