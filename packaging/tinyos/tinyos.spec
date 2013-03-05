Summary: An event-based operating environment designed for use with embedded networked sensors.
Name: TinyOS
BuildArchitectures: noarch
Version: %{version}
Release: %{release}
License: Please see source
Packager: TinyOS Group, UC Berkeley
Group: Development/System
URL: www.tinyos.net
Source0: tinyos-%{version}.tar.bz
Prefix: /opt
Requires: tinyos-tools >= 1.4.1, nesc >= 1.3.4
AutoReqProv: 0
BuildRoot: %{_builddir}/%{name}-%{version}-%{release}.%{_arch}

%global _binaries_in_noarch_packages_terminate_build 0

%description
TinyOS is an event based operating environment designed for use with
embedded networked sensors.  It is designed to support the concurrency
intensive operations required by networked sensors while requiring minimal
hardware resources. For a full analysis and description of the
TinyOS system, its component model, and its implications for Networked
Sensor Architectures please see: "Architectural Directions for Networked
Sensors" which can be found off of http://www.tinyos.net

%install
rm -rf %{buildroot}
rsync -a %{sourcedir} %{buildroot}

%files
%defattr(-,root,root)
/

