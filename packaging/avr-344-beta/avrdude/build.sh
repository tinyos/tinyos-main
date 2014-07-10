#!/bin/bash

COMMON_FUNCTIONS_SCRIPT=../../functions-build.sh
source ${COMMON_FUNCTIONS_SCRIPT}

SOURCENAME=avrdude
SOURCEVERSION=6.0.1

SOURCEDIRNAME=${SOURCENAME}-${SOURCEVERSION}
SOURCEFILENAME=${SOURCEDIRNAME}.tar.gz

PREFIX=/usr
MAKE="make -j4"
download()
{
    [[ -a ${SOURCEFILENAME} ]] \
	|| wget http://download.savannah.gnu.org/releases/${SOURCENAME}/${SOURCEFILENAME}
}

unpack()
{
    tar -xzf ${SOURCEFILENAME}
}

build()
{   
    set -e
    (
	cd ${SOURCEDIRNAME}
	CC=i686-w64-mingw32-gcc ./configure --prefix=${PREFIX} --sysconfdir=/etc
	make
	cd ..
    )
}

installto()
{
  cd ${SOURCEDIRNAME}
  ${MAKE} DESTDIR=${INSTALLDIR} install
  cd ..
}

package_rpm(){
  package_rpm_from ${INSTALLDIR} ${SOURCEVERSION} ${PACKAGE_RELEASE} / avrdude.spec
}

cleanbuild(){
  remove ${SOURCEDIRNAME}
  remove ${INSTALLDIR}
}

cleandownloaded(){
  remove ${SOURCEFILENAME}
}

cleaninstall(){
  remove ${INSTALLDIR}
}

BUILD_ROOT=$(pwd)
case $1 in
    download)
	download
	;;

    clean)
	cleanbuild
	;;

    veryclean)
	cleanbuild
	cleandownloaded
	;;

    rpm)
	setup_package_target ${SOURCENAME}-tinyos ${SOURCEVERSION} ${PACKAGE_RELEASE}
	download
	unpack
	build
	installto
	package_rpm
	cleaninstall
	;;
	
    local)
	setup_local_target
	download
	unpack
	build
	installto
	;;
    *)
	echo -e "\n./build.sh <target>"
	echo -e "    local | rpm | clean | veryclean | download"
esac
