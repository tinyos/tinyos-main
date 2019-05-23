%define version 1.3.0
%define theprefix /usr

Summary: nesC compiler 
Name: nesc
Version: 1.3.0
Release: 1%{dist}
License: GNU GPL Version 2
Packager: TinyOS Group, UC Berkeley
Group: Development/Tools
URL: http://sourceforge.net/projects/nescc
Source0: %{name}-%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}-root

%description
nesC is a compiler for a C-based language designed to support embedded
systems including TinyOS. nesC provides several advantages for the
TinyOS compiler infrastructure: improved syntax, support for full type
safety, abundant error reporting, generic components, and Java-like
interfaces.

%prep
%setup -q

%build
./configure --prefix=%{theprefix}
make 

%install
rm -rf %{buildroot}%{theprefix}
make prefix=%{buildroot}%{theprefix} install

%clean
rm -rf $RPM_BUILD_DIR/%{name}-%{version}

%files
%defattr(-,root,root,-)
%{theprefix}
%doc

%changelog
* Wed Aug 6 2008  <david.e.gay@intel.com> 1.3.0
- Deputy support
* Tue Jul 3 2007  <david.e.gay@intel.com> 1.2.9
* Wed Dec 20 2006  <david.e.gay@intel.com> 1.2.8a
* Fri Dec 1 2006  <david.e.gay@intel.com> 1.2.8
* Thu Jul 6 2006  <kwright@archrock.com> 1.2.7a
* Wed Jun 28 2006  <kwright@archrock.com> 1.2.7
- Version 1.2.7
* Fri Feb 3 2006  <kwright@cs.berkeley.edu> 1.2.4
- Version 1.2.4
* Mon Mar 14 2005  <kwright@cs.berkeley.edu> 1.1.2b
- Version 1.1.2b; use buildroot
* Tue Jul 27 2004  <dgay@intel-research.net> 1.1.2-1w
- Version 1.1.2
* Fri Sep 26 2003 root <kwright@cs.utah.edu> 1.1-1
- New source
* Fri Sep 19 2003 root <kwright@cs.utah.edu> 1.1pre4-2
- Removed set-mote-id
* Fri Sep 12 2003 root <kwright@cs.utah.edu> 1.1pre4-1
- New source
* Fri Aug 15 2003 root <kwright@cs.utah.edu> 1.1pre2-1
- Initial build.

