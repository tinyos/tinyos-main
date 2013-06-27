#!/bin/bash
#
# Duplicates what is in tools/platforms/msp430/toolchain*
#
# BUILD_ROOT is assumed to be the same directory as the build.sh file.
#
# set TOSROOT to the head of the tinyos source tree root.
# used to find default PACKAGES_DIR.
#
#
# Env variables used....
#
# TOSROOT	head of the tinyos source tree root.  Used for base of default repo
# PACKAGES_DIR	where packages get stashed.  Defaults to $(TOSROOT)/packages
# REPO_DEST	Where the repository is being built (no default)
# DEB_DEST	final home once installed.
# CODENAME	which part of the repository to place this build in.
#
# REPO_DEST	must contain a conf/distributions file for reprepro to work
#		properly.   One can be copied from $(TOSROOT)/tools/repo/conf.
#

COMMON_FUNCTIONS_SCRIPT=../functions-build.sh
source ${COMMON_FUNCTIONS_SCRIPT}


SOURCENAME=binutils
SOURCEVERSION=2.22
SOURCEDIRNAME=${SOURCENAME}-${SOURCEVERSION}
SOURCEFILENAME=${SOURCEDIRNAME}.tar.bz2
#PACKAGE_RELEASE=1
PATCHZIP="avr8-gnu-toolchain-3.4.0.663-source.zip"
PREFIX=/usr
MAKE="make -j8"

download()
{
	check_download ${SOURCEFILENAME}
	if [ "$?" -eq "1" ]; then
		wget ftp://ftp.gnu.org/gnu/${SOURCENAME}/${SOURCEFILENAME}
	fi
	check_download ${PATCHZIP}
	if [ "$?" -eq "1" ]; then
		wget http://www.atmel.com/Images/${PATCHZIP}
	fi
}

unpack()
{
  tar -xjf ${SOURCEFILENAME}
  unzip ${PATCHZIP}
  cp source/avr/binutils/* ${SOURCEDIRNAME}
  rm -rf source
  cp 505-bfd_reloc_avr_7_lds16.patch ${SOURCEDIRNAME}
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
  remove ${SOURCEFILENAME} ${PATCHZIP}
}

cleaninstall(){
  remove ${INSTALLDIR}
}

#main funcition
BUILD_ROOT=$(pwd)
case $1 in
  test)
		download
		unpack
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

