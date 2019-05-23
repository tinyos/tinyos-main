Summary: An event-based operating environment designed for use with embedded networked sensors.
Name: %{getenv:PKG_NAME}
BuildArchitectures: noarch
Version: %{getenv:PKG_VERSION}
Release: %{getenv:PKG_RELEASE}
License: Please see source
Packager: TinyOS Group, UC Berkeley
Group: Development/System
URL: www.tinyos.net
Source0: tinyos-%{version}.tar.gz
Prefix: /opt
Requires: tinyos-tools >= 1.4.1, nesc >= 1.3.4
AutoReqProv: 0

%global _binaries_in_noarch_packages_terminate_build 0

%description
TinyOS is an event based operating environment designed for use with
embedded networked sensors.  It is designed to support the concurrency
intensive operations required by networked sensors while requiring minimal
hardware resources. For a full analysis and description of the
TinyOS system, its component model, and its implications for Networked
Sensor Architectures please see: "Architectural Directions for Networked
Sensors" which can be found off of http://www.tinyos.net

%prep
cd $RPM_BUILD_DIR
tar -xzf $RPM_SOURCE_DIR/tinyos-%{version}.tar.gz
mv tinyos-%{version} %{name}-%{version}
cd %{name}-%{version}

%install
# export TOSROOT=$RPM_BUILD_DIR/%{name}-%{version}
# export TOSDIR=$TOSROOT/tos
# %ifos linux
# export CLASSPATH=$TOSROOT/support/sdk/java:.
# %else
# export CLASSPATH=`cygpath -w $TOSROOT/support/sdk/java`\;.
# %endif
# cd $TOSROOT/support/sdk/java
# pwd
# ls
# make tinyos.jar; make clean
rm -rf %{buildroot}/opt/tinyos-2.1.2
mkdir -p %{buildroot}/opt
cp -a $RPM_BUILD_DIR/%{name}-%{version} %{buildroot}/opt/tinyos-%{version}

%clean
rm -rf %{buildroot}

%files
%defattr(-,root, root,-)
/opt/tinyos-2.1.2/

