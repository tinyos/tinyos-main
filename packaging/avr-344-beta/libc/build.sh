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


SOURCENAME=avr-libc
SOURCEVERSION=1.8.0
ATMELVERSION=3.4.4
SOURCEDIRNAME=libc/${SOURCENAME}
SOURCEFILENAME=${SOURCENAME}-${SOURCEVERSION}.tar.bz2
HEADERVERSION=6.2.0.334
HEADERFILENAME=avr8-headers-${HEADERVERSION}.zip
HEADERDIRNAME=avr
#PACKAGE_RELEASE=1
PREFIX=/usr
MAKE="make -j4"

download()
{
  check_download ${SOURCEFILENAME}
  if [ "$?" -eq "1" ]; then
    wget http://distribute.atmel.no/tools/opensource/Atmel-AVR-GNU-Toolchain/${ATMELVERSION}/${SOURCEFILENAME}
  fi
#The header files are already included in the tarball
#   check_download ${HEADERFILENAME}
#   if [ "$?" -eq "1" ]; then
#     wget http://distribute.atmel.no/tools/opensource/Atmel-AVR-GNU-Toolchain/${ATMELVERSION}/${HEADERFILENAME}
#   fi
}

unpack()
{
  tar -xjf ${SOURCEFILENAME}
#   unzip ${HEADERFILENAME}
}

build()
{
  set -e
  (
#     cd ${HEADERDIRNAME}
#     for i in io[0-9a-zA-Z]*.h
#     do
#       cp --verbose --force $i ../${SOURCEDIRNAME}/include/avr
#     done
#     cd ..
    cd ${SOURCEDIRNAME}
    ./bootstrap
    ./configure --host=avr\
                --prefix="${PREFIX}" \
                --disable-versioned-doc
    ${MAKE}
  )
}

installto()
{
  cd ${SOURCEDIRNAME}
  ${MAKE} tooldir=/usr DESTDIR=${INSTALLDIR} install
}

package_deb(){
  package_deb_from ${INSTALLDIR} ${SOURCEVERSION}-${PACKAGE_RELEASE} libc.control
}

package_rpm(){
  package_rpm_from ${INSTALLDIR} ${SOURCEVERSION} ${PACKAGE_RELEASE} ${PREFIX} libc.spec
}

cleanbuild(){
  remove ${SOURCEDIRNAME}
  remove ${HEADERDIRNAME}
}

cleandownloaded(){
  remove ${SOURCEFILENAME} ${HEADERFILENAME}
}

cleaninstall(){
  remove ${INSTALLDIR}
}

#main funcition
BUILD_ROOT=$(pwd)
case $1 in
  test)
    unpack
    cd ${BUILD_ROOT}
    build
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
    setup_package_target ${SOURCENAME}-tinyos-beta ${SOURCEVERSION} ${PACKAGE_RELEASE}
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
    setup_package_target ${SOURCENAME}-tinyos ${SOURCEVERSION} ${PACKAGE_RELEASE}
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

