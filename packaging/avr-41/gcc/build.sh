#!/bin/bash
#
# Duplicates what is in tools/platforms/msp430/toolchain*
#
# BUILD_ROOT is assumed to be the same directory as the build.sh file.
#
# set TINYOS_ROOT_DIR to the head of the tinyos source tree root.
# used to find default PACKAGES_DIR.
#
#
# Env variables used....
#
# TINYOS_ROOT_DIR	head of the tinyos source tree root.  Used for base of default repo
# PACKAGES_DIR	where packages get stashed.  Defaults to $(TINYOS_ROOT_DIR)/packages
# REPO_DEST	Where the repository is being built (no default)
# DEB_DEST	final home once installed.
# CODENAME	which part of the repository to place this build in.
#
# REPO_DEST	must contain a conf/distributions file for reprepro to work
#		properly.   One can be copied from $(TINYOS_ROOT_DIR)/tools/repo/conf.
#

COMMON_FUNCTIONS_SCRIPT=../../functions-build.sh
source ${COMMON_FUNCTIONS_SCRIPT}


SOURCENAME=gcc
SOURCEVERSION=4.1.2
SOURCEDIRNAME=${SOURCENAME}-${SOURCEVERSION}
SOURCEFILENAME=${SOURCEDIRNAME}.tar.bz2
#PACKAGE_RELEASE=1
PATCHES="00-gcc-4.1.2-version-WinAVR.patch 20-gcc-4.1.2-libiberty-Makefile.in.patch 40-gcc-4.1.2-bug-28902.patch 44-gcc-4.1.2-bug-30289.patch 50-gcc-4.1.2-newdevices.patch 10-gcc-4.1.2-c-incpath.patch 30-gcc-4.1.2-binary-constants.patch 42-gcc-4.1.2-bug-31137.patch 45-gcc-4.1.2-bug-18989.patch 51-gcc-4.1.2-atmega256x.patch 11-gcc-4.1.2-exec-prefix.patch 31-gcc-4.1.2-isr-alias.patch 43-gcc-4.1.2-bug-19087.patch 46-gcc-4.1.2-bug-30483.patch"
PREFIX=/usr
MAKE="make -j8"

download()
{
	check_download ${SOURCEFILENAME}
	if [ "$?" -eq "1" ]; then
		wget ftp://ftp.gnu.org/gnu/${SOURCENAME}/${SOURCEDIRNAME}/${SOURCEFILENAME}
	fi
	check_download ${PATCHES}
	if [ "$?" -eq "1" ]; then
		svn co https://winavr.svn.sourceforge.net/svnroot/winavr/trunk/patches/${SOURCENAME}/${SOURCEVERSION}/ .
		rm -rf .svn
		rm -rf 41-gcc-4.1.2-bug-25448.patch #this creates a tinyos critical bug
	fi
}

unpack()
{
  tar -xjf ${SOURCEFILENAME}
  cp *.patch ${SOURCEDIRNAME}
  cd ${SOURCEDIRNAME}
  cat *.patch|patch -p0
}

build()
{
  set -e
  (
    cd ${SOURCEDIRNAME}
    ./configure --prefix=${PREFIX} --disable-libssp --disable-nls --enable-languages=c,c++ --infodir=${PREFIX}/share/info --libdir=${PREFIX}/lib --libexecdir=${PREFIX}/lib --mandir=${PREFIX}/share/man --target=avr --with-ld=/usr/bin/avr-ld --with-as=/usr/bin/avr-as
    ${MAKE}
  )
}

installto()
{
	cd ${SOURCEDIRNAME}
  ${MAKE} tooldir=/usr DESTDIR=${INSTALLDIR} install
  #cleanup
  rm -f ${INSTALLDIR}/usr/lib/libiberty.a
  rm -f ${INSTALLDIR}/usr/lib64/libiberty.a
  rm -rf ${INSTALLDIR}/usr/share/info
  rm -rf ${INSTALLDIR}/usr/share/man/man7
}

package_deb(){
  package_deb_from ${INSTALLDIR} ${SOURCEVERSION}-${PACKAGE_RELEASE} gcc.control
}

package_rpm(){
  package_rpm_from ${INSTALLDIR} ${SOURCEVERSION} ${PACKAGE_RELEASE} ${PREFIX} gcc.spec
}

cleanbuild(){
  remove ${SOURCEDIRNAME}
}

cleandownloaded(){
  remove ${SOURCEFILENAME} ${PATCHES}
}

cleaninstall(){
  remove ${INSTALLDIR}
}

#main funcition
BUILD_ROOT=$(pwd)
case $1 in
  test)
		setup_package_target avr-${SOURCENAME}-tinyos ${SOURCEVERSION} ${PACKAGE_RELEASE}
		installto
    cd ${BUILD_ROOT}
    package_deb
    cd ${BUILD_ROOT}
    cleaninstall
    ;;

  download)
    download
    ;;
	
	
  clean)
    cleanbuild
    ;;

  veryclean)
    cleanbuild
    cd ${BUILD_ROOT}
    cleandownloaded
    ;;

  deb)
		setup_package_target avr-${SOURCENAME}-tinyos ${SOURCEVERSION} ${PACKAGE_RELEASE}
		cd ${BUILD_ROOT}
    download
    cd ${BUILD_ROOT}
    unpack
    cd ${BUILD_ROOT}
    build
    cd ${BUILD_ROOT}
    installto
    cd ${BUILD_ROOT}
    package_deb
    cd ${BUILD_ROOT}
    cleaninstall
    ;;

  rpm)
		setup_package_target avr-${SOURCENAME}-tinyos ${SOURCEVERSION} ${PACKAGE_RELEASE}
		cd ${BUILD_ROOT}
    download
    cd ${BUILD_ROOT}
    unpack
    cd ${BUILD_ROOT}
    build
    cd ${BUILD_ROOT}
    installto
    cd ${BUILD_ROOT}
    package_rpm
    cd ${BUILD_ROOT}
    cleaninstall
    ;;

  local)
    setup_local_target
    cd ${BUILD_ROOT}
    download
    cd ${BUILD_ROOT}
    unpack
    cd ${BUILD_ROOT}
    build
    cd ${BUILD_ROOT}
    installto
    ;;

  *)
    echo -e "\n./build.sh <target>"
    echo -e "    local | rpm | deb | clean | veryclean | download"
esac

