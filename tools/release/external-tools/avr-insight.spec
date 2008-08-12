%define theprefix /usr

Summary: Insight GDB GUI	
Name: avr-insight
Version: 6.3
Release: 1
Packager: TinyOS Group, UC Berkeley
License: GNU GPL
Group: Development/Tools
URL: httphttp://ftp.gnu.org/gnu/gdb/gdb-6.2.tar.gz 
Source0: %{name}-%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}-root

%description
This package includes gdb and insight, a graphical user interface to GDB
written in Tcl/Tk originally by Red Hat and Cygnus.

%prep
%setup -q

%build
./configure --prefix=%{theprefix} --target=avr --with-gnu-ld --with-gnu-as --disable-nls 
make

%install
rm -rf %{buildroot}/usr/local
make prefix=%{buildroot}/usr/local install
cd %{buildroot}/usr/local
rm info/bfd.info* info/configure.info* info/dir info/standards.info
rm lib/libiberty.a

%clean
rm -rf $RPM_BUILD_DIR/%{name}-%{version}
rm -rf $RPM_SOURCE_DIR/%{name}-%{version}

%files
%defattr(-,root,root,-)
/usr/local
%doc

%changelog
* Thu Aug 28 2003 root <kwright@cs.berkeley.edu> pre6.0cvs-1.2
- Removed last of the file conflicts and changed name to avr-insight
* Fri Aug 15 2003 root <kwright@cs.berkeley.edu> pre6.0cvs-1
- Initial build.


