Summary: nesC compiler
Name: nesc
Version: %{version}
Release: %{release}
License: GNU GPL Version 2
Packager: Razvan Musaloiu-E. <razvan@musaloiu.com>
Group: Development/Tools

%description
nesC is a compiler for a C-based language designed to support embedded
systems including TinyOS. nesC provides several advantages for the
TinyOS compiler infrastructure: improved syntax, support for full type
safety, abundant error reporting, generic components, and Java-like
interfaces.

%install
rsync -a %{prefix} %{buildroot}

%files
/usr
