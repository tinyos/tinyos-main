Summary: TinyOS tools 
Name: tinyos-tools-14
Version: %{version}
Release: %{release}
License: GNU GPL Version 2
Packager: Andras Biro
Group: Development/Tools
URL: http://www.tinyos.net
Source0: %{name}-%{version}.tar.gz
BuildRoot: %{_builddir}/%{name}-%{version}-%{release}.%{_arch}
# This makes cygwin happy
Provides: /bin/sh /bin/bash
Requires: nesc >= 1.3

%description
Tools for use with tinyos. Includes, for example: uisp, motelist, pybsl, mig,
ncc and nesdoc. The source for these tools is found in the TinyOS CVS
repository under tinyos-2.x/tools.

%install
rm -rf %{buildroot}
rsync -a %{sourcedir} %{buildroot}

%files
%defattr(-,root,root)
/

%post
if [ -f $RPM_INSTALL_PREFIX/lib/tinyos/giveio-install ]; then
  uname|grep -q WOW64
  if [ $? -ne 0 ]; then
	(cd $RPM_INSTALL_PREFIX/lib/tinyos; ./giveio-install --install)
  else
    echo "Warning: giveio.sys is not working on 64-bit Windows, therefore parellel port targets won't work with uisp"
  fi
fi
echo "Installing JNI libraries"
/usr/bin/tos-install-jni