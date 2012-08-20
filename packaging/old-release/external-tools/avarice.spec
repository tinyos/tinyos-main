%define theprefix /usr

Summary: AVaRICE - an interface for Atmel JTAG ICE to GDB
Name: avarice
Version: 2.4
Release: 1
Packager: kwright, TinyOS Group, UC Berkeley
License: GNU GPL
Group: Development/Tools 
URL: http://sourceforge.net/projects/avarice/
Source0: avarice-%{version}.tar.bz2
BuildRoot: %{_tmppath}/%{name}-root

%description
AVaRICE compiled for the %{target} platform.
AVaRICE is a program interfacing the Atmel JTAG ICE to GDB. 
Users can debug their embedded AVR target via the Atmel JTAG 
ICE using GDB.

%prep
%setup -q

%build
./configure --prefix=/usr
make

%install
rm -rf %{buildroot}%{theprefix}
make prefix=%{buildroot}%{theprefix} install

%clean
rm -rf $RPM_BUILD_DIR/%(name)-%(version)
rm -rf $RPM_SOURCE_DIR/%(name)-%(version)

%files
%defattr(-,root,root,-)
%{theprefix}
%doc

%changelog
* Fri Feb 3 2006 kwright <kwright@cs.berkeley.edu>
- Update to avarice 2.4; create multi-platform file
* Tue Mar 1 2005 kwright <kwright@cs.berkeley.edu>
- Update for TinyOS 1.2 build.
* Mon Aug 18 2003 kwright <kwright@cs.berkeley.edu>
- Initial build.


