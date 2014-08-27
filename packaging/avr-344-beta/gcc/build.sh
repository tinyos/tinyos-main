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
SOURCEVERSION=4.8.1
ATMELVERSION=3.4.4
GMPVERSION=5.0.2
MPFRVERSION=3.0.0
MPCVERSION=0.9
BUILDDIR=build
SOURCEDIRNAME=${SOURCENAME}
SOURCEFILENAME=avr-${SOURCENAME}-${SOURCEVERSION}.tar.bz2
GMPDIRNAME=gmp-${GMPVERSION}
GMPFILENAME=gmp-${GMPVERSION}.tar.bz2
MPFRDIRNAME=mpfr-${MPFRVERSION}
MPFRFILENAME=mpfr-${MPFRVERSION}.tar.bz2
MPCDIRNAME=mpc-${MPCVERSION}
MPCFILENAME=mpc-${MPCVERSION}.tar.gz

#PACKAGE_RELEASE=1
PREFIX=/usr
MAKE="make -j4"

download()
{
  check_download ${GMPFILENAME}
  if [ "$?" -eq "1" ]; then
    wget https://ftp.gnu.org/gnu/gmp/${GMPFILENAME}
  fi
  check_download ${MPFRFILENAME}
  if [ "$?" -eq "1" ]; then
    wget https://ftp.gnu.org/gnu/mpfr/${MPFRFILENAME}
  fi
  check_download ${MPCFILENAME}
  if [ "$?" -eq "1" ]; then
    wget http://www.multiprecision.org/mpc/download/${MPCFILENAME}
  fi
  check_download ${SOURCEFILENAME}
  if [ "$?" -eq "1" ]; then
    wget http://distribute.atmel.no/tools/opensource/Atmel-AVR-GNU-Toolchain/${ATMELVERSION}/${SOURCEFILENAME}
  fi
}

unpack()
{
  tar -xjf ${SOURCEFILENAME}
  tar -xjf ${GMPFILENAME}
  tar -xjf ${MPFRFILENAME}
  tar -xzf ${MPCFILENAME}
  cd ${SOURCEDIRNAME}
  ln -s ../${GMPDIRNAME} gmp
  ln -s ../${MPFRDIRNAME} mpfr
  ln -s ../${MPCDIRNAME} mpc
  patch -p0 <../bugfix60486.patch
}


build()
{
  set -e
  (
    cd ${SOURCEDIRNAME}
#     these were in the atmel script's but it didn't make any difference
#     pushd gcc/config/avr/
#     sh genopt.sh avr-mcus.def > avr-tables.opt
#     cat avr-mcus.def | awk -f genmultilib.awk FORMAT="Makefile" > t-multilib 
#     popd
#     #don't force old autoconf
#     sed -i 's/  \[m4_fatal(\[Please use exactly Autoconf \]/  \[m4_errprintn(\[Please use exactly Autoconf \]/g' ./config/override.m4 || task_error "sed failed"
#     autoconf
    
    mkdir -p ${BUILDDIR}
    cd ${BUILDDIR}
    CFLAGS="-Os -g0 -s" LDFLAGS="-L${PREFIX}/lib" CPPFLAGS="" \
            ../configure \
            --target=avr\
            --prefix=${PREFIX}\
            --libdir=${PREFIX}/lib\
            --libexecdir=${PREFIX}/lib\
            --infodir=${PREFIX}/share/info\
            --mandir=${PREFIX}/share/man\
            --enable-languages="c,c++"\
            --with-dwarf2\
            --enable-doc\
            --disable-libada\
            --disable-libssp\
            --disable-nls\
            --with-ld=${PREFIX}/bin/avr-ld\
            --with-as=${PREFIX}/bin/avr-as\
            --with-avrlibc=yes
    ${MAKE} all
    #../${SOURCEDIRNAME}/configure --prefix=${PREFIX} --disable-libssp --disable-nls --enable-languages=c,c++ --infodir=${PREFIX}/share/info --libdir=${PREFIX}/lib --libexecdir=${PREFIX}/lib --mandir=${PREFIX}/share/man --target=avr --with-ld=/usr/bin/avr-ld --with-as=/usr/bin/avr-as
    #${MAKE}
  )
}

installto()
{
  cd ${SOURCEDIRNAME}/${BUILDDIR}
  ${MAKE} tooldir=/usr DESTDIR=${INSTALLDIR} install
  #cleanup
  rm -f ${INSTALLDIR}/usr/lib/libiberty.a
  rm -f ${INSTALLDIR}/usr/lib64/libiberty.a
  rm -rf ${INSTALLDIR}/usr/share/info
  rm -rf ${INSTALLDIR}/usr/share/man/man7
  #strip executables
  cd ${INSTALLDIR}/usr/bin/
  strip *
  cd ${INSTALLDIR}/usr/lib/gcc/avr/${SOURCEVERSION}/
  for binary in cc1 cc1plus collect2 lto-wrapper lto1 "install-tools/fixincl"
  do
    strip $binary
  done
}

package_deb(){
  package_deb_from ${INSTALLDIR} ${SOURCEVERSION}-${PACKAGE_RELEASE} gcc.control
}

package_rpm(){
  package_rpm_from ${INSTALLDIR} ${SOURCEVERSION} ${PACKAGE_RELEASE} ${PREFIX} gcc.spec
}

cleanbuild(){
  remove ${SOURCEDIRNAME}
  remove ${GMPDIRNAME}
  remove ${MPCDIRNAME}
  remove ${MPFRDIRNAME}
}

cleandownloaded(){
  remove ${SOURCEFILENAME} ${GMPFILENAME} ${MPCFILENAME} ${MPFRFILENAME}
}

cleaninstall(){
  remove ${BUILDDIR}
  remove ${INSTALLDIR}
}

#main funcition
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
    cd ${BUILD_ROOT}
    cleandownloaded
    ;;
  
  deb)
    setup_package_target ${SOURCENAME}-avr-tinyos-beta ${SOURCEVERSION} ${PACKAGE_RELEASE}
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

