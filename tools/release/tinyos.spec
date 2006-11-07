Summary: An event-based operating environment designed for use with embedded networked sensors.
Name: tinyos
BuildArchitectures: noarch
Version: 2.0.0
Release: 2
License: Please see source
Packager: TinyOS Group, UC Berkeley
Group: Development/System
URL: www.tinyos.net
Source0: %{name}-%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}-root
Prefix: /opt
Requires: tinyos-tools >= 1.2.2, nesc >= 1.2.7

%description
TinyOS is an event based operating environment designed for use with 
embedded networked sensors.  It is designed to support the concurrency
intensive operations required by networked sensors while requiring minimal
hardware resources. For a full analysis and description of the
TinyOS system, its component model, and its implications for Networked
Sensor Architectures please see: "Architectural Directions for Networked
Sensors" which can be found off of http://www.tinyos.net

%prep
%setup -q

%install
rm -rf %{buildroot}/opt/tinyos-2.x
mkdir -p %{buildroot}/opt
export TOSROOT=$RPM_BUILD_DIR/%{name}-%{version}
export TOSDIR=$TOSROOT/tos
%ifos linux
export CLASSPATH=$TOSROOT/support/sdk/java:.
%else
export CLASSPATH=`cygpath -w $TOSROOT/support/sdk/java`\;.
%endif
cd support/sdk/java
pwd
ls
make tinyos.jar; make clean
cp -a $RPM_BUILD_DIR/%{name}-%{version} %{buildroot}/opt/tinyos-2.x

%clean
rm -rf %{buildroot}

%files
%defattr(-,root, root,-)
/opt/tinyos-2.x/

