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


SOURCENAME=binutils
SOURCEVERSION=2.17
SOURCEDIRNAME=${SOURCENAME}-${SOURCEVERSION}
SOURCEFILENAME=${SOURCEDIRNAME}.tar.bz2
#PACKAGE_RELEASE=1
PATCHES="30-binutils-2.17-avr-size.patch 31-binutils-2.17-avr-coff.patch 50-binutils-2.17-atmega256x.patch 51-binutils-2.17-newdevices.patch"
PREFIX=/usr
MAKE="make -j8"

download()
{
	check_download ${SOURCEFILENAME}
	if [ "$?" -eq "1" ]; then
		wget ftp://ftp.gnu.org/gnu/${SOURCENAME}/${SOURCEFILENAME}
	fi
	check_download ${PATCHES}
	if [ "$?" -eq "1" ]; then
		svn co https://winavr.svn.sourceforge.net/svnroot/winavr/trunk/patches/${SOURCENAME}/${SOURCEVERSION}/ .
		rm -rf .svn
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
    ./configure --prefix=${PREFIX} --disable-nls --infodir=${PREFIX}/share/info --libdir=${PREFIX}/lib --mandir=${PREFIX}/share/man --disable-werror --target=avr
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
  rm -f ${INSTALLDIR}/usr/share/info/dir
  #remove everything without avr
  for filename in `ls ${INSTALLDIR}/usr/bin/|grep -v avr`; do
		rm -f ${INSTALLDIR}/usr/bin/$filename
	done
	#rename info files to avr-*
	for filename in `ls ${INSTALLDIR}/usr/share/info`; do
		mv ${INSTALLDIR}/usr/share/info/$filename ${INSTALLDIR}/usr/share/info/avr-$filename
	done
}

package_deb(){
  package_deb_from ${INSTALLDIR} ${SOURCEVERSION}-${PACKAGE_RELEASE} binutils.control
}

package_rpm(){
  package_rpm_from ${INSTALLDIR} ${SOURCEVERSION} ${PACKAGE_RELEASE} ${PREFIX} binutils.spec
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
		installto
# 		cd ${BUILD_ROOT}
#		package_deb
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

