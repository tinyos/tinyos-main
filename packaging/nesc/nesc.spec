Summary: nesC compiler
Name: nesc
Version: %{version}
Release: %{release}
License: GNU GPL Version 2
Packager: Razvan Musaloiu-E. <razvan@musaloiu.com>
Group: Development/Tools
BuildRoot: %{_builddir}/%{name}-%{version}-%{release}.%{_arch}

%description
nesC is a compiler for a C-based language designed to support embedded
systems including TinyOS. nesC provides several advantages for the
TinyOS compiler infrastructure: improved syntax, support for full type
safety, abundant error reporting, generic components, and Java-like
interfaces.

%install
rm -rf %{buildroot}
rsync -a %{prefix} %{buildroot}

%files
/usr
