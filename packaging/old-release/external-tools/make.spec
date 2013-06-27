Summary: GNU Make 3.80 patched for use with TinyOS
Name: make
Version: 3.80tinyos
Release: 1
Packager: TinyOS Group, UC Berkeley
License: GNU GPL
Group: Development/Tools
URL: http://www.tinyos.net/dist-2.0.0
Source0: %{name}-%{version}.tar.bz2
BuildRoot: %{_tmppath}/%{name}-root

%description
GNU make 3.80 patched for use with TinyOS. 

%prep
%setup -q

%build
./configure --prefix=/usr
make

%pre
# This worked in linux, but not in cygwin:
#   cp: `/usr/bin/make' and `/usr/bin/make-unpatched' are the same file
#   error: %pre(make-3.80tinyos-1) scriptlet failed, exit status 1
#   error:   install: %pre scriptlet failed (2), skipping make-3.80tinyos-1
# cp /usr/bin/make /usr/bin/make-unpatched

%install
rm -rf %{buildroot}/usr
make prefix=%{buildroot}/usr install
cd %{buildroot}/usr
# just install the modified make
rm -rf man share info

%clean
rm -rf $RPM_BUILD_DIR/%{name}-%{version}
rm -rf $RPM_SOURCE_DIR/%{name}-%{version}

%files
%defattr(-,root,root,-)
/usr
%doc

%changelog
* Mon May 23 2005 kwright <kwright@cs.berkeley.edu> 
- Initial build.

#
# Use Phil's tgz to build make. Before installing,
# move existing to /usr/bin/make-unpatched. 
#
# In order to not generate the debuginfo for this, the 
# users's .rpmmacro must have this line:
#    %debug_package %{nil}
#

