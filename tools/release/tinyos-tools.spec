%define debug_package %{nil}

Summary: TinyOS tools 
Name: tinyos-tools
Version: 1.2.3
Release: 1
License: Please see source
Group: Development/System
URL: http://www.tinyos.net/
BuildRoot: %{_tmppath}/%{name}-root
Source0: %{name}-%{version}.tar.gz
# This makes cygwin happy
Provides: /bin/sh /bin/bash
Requires: nesc >= 1.2.7

%description
Tools for use with tinyos. Includes, for example: uisp, motelist, pybsl, mig,
ncc and nesdoc. The source for these tools is found in the TinyOS CSV
repository under tinyos-2.x/tools.

%prep
%setup -q -n %{name}-%{version}

%build
cd tools
./Bootstrap
TOSDIR=/opt/tinyos-2.x/tos ./configure --prefix=/usr
make

%install
rm -rf %{buildroot}
cd tools
make install prefix=%{buildroot}/usr

%clean
rm -rf $RPM_BUILD_DIR/%{name}-%{version}
rm -rf $RPM_SOURCE_DIR/%{name}-%{version}

%files
%defattr(-,root,root,-)
/usr/
%attr(4755, root, root) /usr/bin/uisp*

%post
if [ -z "$RPM_INSTALL_PREFIX" ]; then
  RPM_INSTALL_PREFIX=/usr
fi

# Install giveio (windows only)
if [ -f $RPM_INSTALL_PREFIX/lib/tinyos/giveio-install ]; then
  (cd $RPM_INSTALL_PREFIX/lib/tinyos; ./giveio-install --install)
fi
# Install the JNI;  we can't call tos-install-jni 
# directly because it isn't in the path yet. Stick
# a temporary script in /etc/profile.d and then delete.
jni=`$RPM_INSTALL_PREFIX/bin/tos-locate-jre --jni`
if [ $? -ne 0 ]; then
  echo "Java not found, not installing JNI code"
  exit 0
fi
echo "Installing Java JNI code in $jni ... "
%ifos linux
for lib in $RPM_INSTALL_PREFIX/lib/tinyos/*.so; do 
  install $lib "$jni" || exit 0
done
%else
for lib in $RPM_INSTALL_PREFIX/lib/tinyos/*.dll; do 
  install --group=SYSTEM $lib "$jni" || exit 0
done
%endif
echo "done."

%preun
# Remove JNI code on uninstall

%changelog
* Wed Jul 5 2006 <kwright@archrock.com> 1.2.2-1
* Thu Feb 9 2006 <david.e.gay@intel.com> 1.2.1-2
* Sat Feb 4 2006 <kwright@cs.berkeley.edu> 1.2.1-1
- 1.2.1
* Wed Aug 26 2005 <kwright@cs.berkeley.edu> 1.2.0-beta2.1
- includes dgay fixes for uisp and calling tos-locate-jre from post script
* Wed Aug 17 2005 <kwright@cs.berkeley.edu> 1.2.0-internal2.1
- include fixes/improvements to tos-locate-jre and switch prefix to /usr
* Fri Aug 12 2005  <kwright@cs.berkeley.edu> 1.2.0-internal1.1
- 1.2
* Wed Sep  3 2003  <dgay@barnowl.research.intel-research.net> 1.1.0-internal2.1
- All tools, no java
* Sun Aug 31 2003 root <kwright@cs.berkeley.edu> 1.1.0-internal1.1
- Initial build.
