Summary: nesC compiler 
Name: nesc
Version: PKG_VERSION
Release: PKG_RELEASE
License: GNU GPL Version 2
Packager: Andras Biro, Janos Sallai
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

%files
%defattr(-,root,root,-)
/usr