#!/bin/bash
#
# BUILD_ROOT is assumed to be the same directory as the build.sh file.
#
# mspgcc, msp430 gcc toolchain  DEPRECATED
# 4.5.3-LTS20110716
# binutils	2.21.1a
# gcc		4.5.3
# gdb		7.2a
# mspgcc	20110716
# msp430-libc	20110612
# msp430mcu	20110613
#
# gmp		4.3.2
# mpfr		2.4.2
# mpc		0.8.1
#
# Env variables used....
#
# TINYOS_ROOT_DIR	head of the tinyos source tree root.  Used for base of default repo
# PACKAGES_DIR	where packages get stashed.  Defaults to ${BUILD_ROOT}/packages
# REPO_DEST	Where the repository is being built (${TINYOS_ROOT_DIR}/packaging/repo)
# DEB_DEST	final home once installed.
# CODENAME	which part of the repository to place this build in.
#
# REPO_DEST	must contain a conf/distributions file for reprepro to work
#		properly.   Examples of reprepo configuration can be found in
#               ${TINYOS_ROOT_DIR}/packaging/repo/conf.
#
# we use opt for these tools to avoid conflicting with placement from normal
# distribution paths (debian or ubuntu repositories).
#

BUILD_ROOT=$(pwd)

DEB_DEST=opt/msp430-45
CODENAME=msp430-45
REL=LTS
MAKE_J=-j8

if [[ -z "${TINYOS_ROOT_DIR}" ]]; then
    TINYOS_ROOT_DIR=$(pwd)/../../../..
fi
echo -e "\n*** TINYOS_ROOT_DIR: $TINYOS_ROOT_DIR"
echo "*** Destination: ${DEB_DEST}"

BINUTILS_VER=2.21.1
GCC_VER=4.5.3
GDB_VER=7.2

BINUTILS=binutils-${BINUTILS_VER}
GCC_CORE=gcc-core-${GCC_VER}
GCC=gcc-${GCC_VER}
GDB=gdb-${GDB_VER}

GMP_VER=4.3.2
MPFR_VER=2.4.2
MPC_VER=0.8.1

GMP=gmp-${GMP_VER}
MPFR=mpfr-${MPFR_VER}
MPC=mpc-${MPC_VER}

MSPGCC_VER=20110716
MSPGCC=mspgcc-${MSPGCC_VER}
MSPGCC_DIR=

PATCHES="  msp430-binutils-2.21.1-20110716-sf3143071.patch
  msp430-binutils-2.21.1-20110716-sf3379341.patch
  msp430-binutils-2.21.1-20110716-sf3386145.patch
  msp430-binutils-2.21.1-20110716-sf3400711.patch
  msp430-binutils-2.21.1-20110716-sf3400750.patch
  msp430-gcc-4.5.3-20110706-sf3370978.patch
  msp430-gcc-4.5.3-20110706-sf3390964.patch
  msp430-gcc-4.5.3-20110706-sf3394176.patch
  msp430-gcc-4.5.3-20110706-sf3396639.patch
  msp430-gcc-4.5.3-20110706-sf3409864.patch
  msp430-gcc-4.5.3-20110706-sf3417263.patch
  msp430-gcc-4.5.3-20110706-sf3431602.patch
  msp430-gcc-4.5.3-20110706-sf3433730.patch
  msp430-gcc-4.5.3-20110706-sf3420924.patch
  msp430-gcc-4.5.3-20110706-sf3500740.patch
  msp430-libc-20110612-sf3387164.patch
  msp430-libc-20110612-sf3402836.patch
  msp430mcu-20110613-sf3379189.patch
  msp430mcu-20110613-sf3384550.patch
  msp430mcu-20110613-sf3400714.patch
"

: ${PREFIX:=${TINYOS_ROOT_DIR}/local}


setup_deb()
{
    ARCH_TYPE=$(dpkg-architecture -qDEB_HOST_ARCH)
    PREFIX=${BUILD_ROOT}/debian/${DEB_DEST}
    if [[ -z "${PACKAGES_DIR}" ]]; then
	PACKAGES_DIR=${BUILD_ROOT}/packages
    fi
    mkdir -p ${PACKAGES_DIR}
}


setup_rpm()
{
    PREFIX=${BUILD_ROOT}/fedora/${DEB_DEST}
}


setup_local()
{
    mkdir -p ${TINYOS_ROOT_DIR}/local
    ${PREFIX:=${TINYOS_ROOT_DIR}/local}
}


last_patch()
{
    # We need to use $@ because the file pattern is already expanded.
    if echo $@ | grep -v -q '*'
    then
	echo -n +
	ls -l -t --time-style=+%Y%m%d $@ | awk '{ print +$6}' | head -n1
    fi
}

download()
{
    echo -e "\n*** Downloading ... "
    echo "  ... ${BINUTILS}, ${GCC_CORE}, ${GDB}"
    [[ -a ${BINUTILS}a.tar.bz2 ]] \
	|| wget http://ftp.gnu.org/gnu/binutils/${BINUTILS}a.tar.bz2
    [[ -a ${GCC_CORE}.tar.bz2 ]] \
	|| wget http://ftp.gnu.org/gnu/gcc/${GCC}/${GCC_CORE}.tar.bz2
    [[ -a ${GDB}a.tar.bz2 ]] \
	|| wget http://ftp.gnu.org/gnu/gdb/${GDB}a.tar.bz2

    echo "  ... ${MPFR}, ${GMP}, ${MPC}"
    [[ -a ${MPFR}.tar.bz2 ]] \
	|| wget http://ftp.gnu.org/gnu/mpfr/${MPFR}.tar.bz2
    [[ -a ${GMP}.tar.bz2 ]] \
	|| wget http://ftp.gnu.org/gnu/gmp/${GMP}.tar.bz2
    [[ -a ${MPC}.tar.gz ]] \
	|| wget http://www.multiprecision.org/mpc/download/${MPC}.tar.gz

    echo "  ... ${MSPGCC} patches"
    [[ -a ${MSPGCC}.tar.bz2 ]] \
	|| wget http://sourceforge.net/projects/mspgcc/files/mspgcc/${MSPGCC_DIR}${MSPGCC}.tar.bz2

    # We need to unpack this in order to find what libc to download
    [[ -d ${MSPGCC} ]] \
	|| tar xjf ${MSPGCC}.tar.bz2

    MSP430MCU_VER=$(cat ${MSPGCC}/msp430mcu.version)
    MSP430MCU=msp430mcu-${MSP430MCU_VER}
    echo "      (mcu)  ${MSP430MCU}"

    [[ -a ${MSP430MCU}.tar.bz2 ]] \
	|| wget http://sourceforge.net/projects/mspgcc/files/msp430mcu/${MSP430MCU}.tar.bz2

    MSP430LIBC_VER=$(cat ${MSPGCC}/msp430-libc.version)
    MSP430LIBC=msp430-libc-${MSP430LIBC_VER}
    echo "      (libc) ${MSP430LIBC}"

    [[ -a ${MSP430LIBC}.tar.bz2 ]] \
	|| wget http://sourceforge.net/projects/mspgcc/files/msp430-libc/${MSP430LIBC}.tar.bz2

    # Download bugfix patches from the MSP430 LTS release
    echo "  ... LTS patches"
    [[ -z "${PATCHES}" ]] && echo "      none"
    for f in ${PATCHES}
    do
	# Note: the last_patch function relies on the wget setting the date right.
	[[ -a ${f} ]] \
	    || (echo "    ... ${f}"
	    wget -q http://sourceforge.net/projects/mspgcc/files/Patches/LTS/20110716/${f})
    done
    echo "*** Done"
}

patch_dirs()
{
    echo -e "\n*** Unpacking ${BINUTILS}a.tar.bz2"
    rm -rf ${BINUTILS}
    tar -xjf ${BINUTILS}a.tar.bz2
    set -e
    (
	cd ${BINUTILS}
	echo -e "\n***" mspgcc ${BINUTILS} patch
	cat ../${MSPGCC}/msp430-binutils-${BINUTILS_VER}-*.patch | patch -p1
	echo -e "\n***" LTS binutils bugfix patches...
	cat ../msp430-binutils-*.patch | patch -p1
    )

    echo -e "\n***" Unpacking ${GCC_CORE}, ${MPFR}, ${GMP}, and ${MPC}
    rm -rf ${GCC} ${MPFR} ${GMP} ${MPC}
    echo ${GCC_CORE}.tar.bz2
    tar -xjf ${GCC_CORE}.tar.bz2
    echo ${MPFR}.tar.bz2
    tar -xjf ${MPFR}.tar.bz2
    echo ${GMP}.tar.bz2
    tar -xjf ${GMP}.tar.bz2
    echo ${MPC}.tar.gz
    tar -xzf ${MPC}.tar.gz
    set -e
    (
	cd ${GCC}
	ln -s ../${MPFR} mpfr
	ln -s ../${GMP}  gmp
	ln -s ../${MPC}  mpc

	echo -e "\n***" mspgcc ${GCC} patch
	cat ../${MSPGCC}/msp430-gcc-${GCC_VER}-*.patch | patch -p1
	echo -e "\n*** LTS gcc bugfix patches..."
	cat ../msp430-gcc-*.patch | patch -p1
    )

    echo -e "\n***" Unpacking ${GDB}
    rm -rf ${GDB}
    tar xjf ${GDB}a.tar.bz2
    set -e
    (
	cd ${GDB}
	echo -e "\n***" mspgcc ${GDB} patch
	cat ../${MSPGCC}/msp430-gdb-${GDB_VER}-*.patch | patch -p1

#	echo -e "\n***" LTS gdb bugfix patches...
#	cat ../msp430-gdb-*.patch | patch -p1
    )

    echo -e "\n***" Unpacking ${MSP430MCU}
    rm -rf ${MSP430MCU}
    tar -xjf ${MSP430MCU}.tar.bz2

    set -e
    (
	cd ${MSP430MCU}
	echo -e "\n*** LTS msp430mcu bugfix patches..."
	cat ../msp430mcu-*.patch | patch -p1
    )

    echo -e "\n***" Unpacking ${MSP430LIBC}
    rm -rf ${MSP430LIBC}
    tar xjf ${MSP430LIBC}.tar.bz2
    set -e
    (
	cd ${MSP430LIBC}
	echo -e "\n*** LTS libc bugfix patches..."
	cat ../msp430-libc-*.patch | patch -p1
    )
}

build_binutils()
{
    set -e
    echo -e "\n***" building ${BINUTILS} "->" ${PREFIX}
    (
	cd ${BINUTILS}
	../${BINUTILS}/configure \
	    --prefix=${PREFIX} \
	    --target=msp430
	make ${MAKE_J}
	make install
#	rm -rf ${PREFIX}{/lib*/libiberty.a,/share/info,/share/locale}
	rm -rf ${PREFIX}{/lib*/libiberty.a,/share/locale}
	find ${PREFIX} -empty | xargs rm -rf
    )
#
# ${BUILD_ROOT}/msp430-binutils.files contains all files built so far.
# ie. all files built for binutils.
#
    ( cd $PREFIX ; find . -type f -o -type l) > ${BUILD_ROOT}/msp430-binutils.files
}

package_binutils_deb()
{
    set -e
    VER=${BINUTILS_VER}
    LAST_PATCH=$(last_patch msp430-binutils-*.patch)
    DEB_VER=${VER}-${REL}${MSPGCC_VER}${LAST_PATCH}
    echo -e "\n***" debian archive: ${BINUTILS} \-\> ${PACKAGES_DIR}
    (
	cd ${BINUTILS}
	mkdir -p debian/DEBIAN debian/${DEB_DEST}
	cat ../msp430-binutils.control \
	    | sed 's/@version@/'${DEB_VER}'/' \
	    | sed 's/@architecture@/'${ARCH_TYPE}'/' \
	    > debian/DEBIAN/control
	rsync -a ../debian/${DEB_DEST}/ debian/${DEB_DEST}/
	fakeroot dpkg-deb --build debian .
	mv *.deb ${PACKAGES_DIR}
    )
}

package_binutils_rpm()
{
    VER=${BINUTILS_VER}
    LAST_PATCH=$(last_patch msp430-binutils-*.patch)
    RPM_VER=${VER}+${REL}${MSPGCC_VER}${LAST_PATCH}
    rpmbuild \
	-D "version ${RPM_VER}" \
	-D "release `date +%Y%m%d`" \
	-D "prefix ${PREFIX}" \
	-bb msp430-binutils.spec
}

build_gcc()
{
    set -e
    echo -e "\n***" building ${GCC} "->" ${PREFIX}
    (
	cd $GCC
	rm -rf build
	mkdir build
	cd build
	../configure \
	    --prefix=${PREFIX} \
	    --target=msp430 \
	    --enable-languages=c
#	CPPFLAGS=-D_FORTIFY_SOURCE=0 make ${MAKE_J}
	make ${MAKE_J}
	make install
#	rm -rf ${PREFIX}{/lib*/libiberty.a,/share/info,/share/locale,/share/man/man7}
	rm -rf ${PREFIX}{/lib*/libiberty.a,/share/locale}
	find ${PREFIX} -empty | xargs rm -rf
    )
#
# ${BUILD_ROOT}/msp430-gcc.files contains all files built so far.
# ie. all files built for binutils and gcc.  Its cummulative.
#
    ( cd $PREFIX ; find . -type f -o -type l) > ${BUILD_ROOT}/msp430-gcc.files
}

package_gcc_deb()
{
    set -e
    VER=${GCC_VER}
    LAST_PATCH=$(last_patch msp430-gcc-*.patch)
    DEB_VER=${VER}-${REL}${MSPGCC_VER}${LAST_PATCH}
    echo -e "\n***" debian archive: ${GCC} \-\> ${PACKAGES_DIR}
    (
	cd ${GCC}
	mkdir -p debian/DEBIAN debian/${DEB_DEST}
	cat ../msp430-gcc.control \
	    | sed 's/@version@/'${DEB_VER}'/' \
	    | sed 's/@architecture@/'${ARCH_TYPE}'/' \
	    > debian/DEBIAN/control
	rsync -a ../debian/${DEB_DEST}/ debian/${DEB_DEST}/
	(
	    cd debian/${DEB_DEST}
#
# remove all previously built files.   This leaves only those files we
# have explicilty built.
#
	    cat ${BUILD_ROOT}/msp430-binutils.files | xargs rm -rf
	    find . -empty | xargs rm -rf
	)
	fakeroot dpkg-deb --build debian .
	mv *.deb ${PACKAGES_DIR}
    )
}

package_gcc_rpm()
{
    VER=${GCC_VER}
    LAST_PATCH=$(last_patch msp430-gcc-*.patch)
    RPM_VER=${VER}+${REL}${MSPGCC_VER}${LAST_PATCH}
    rpmbuild \
	-D "version ${RPM_VER}" \
	-D "release `date +%Y%m%d`" \
	-D "prefix ${PREFIX}" \
	-bb msp430-gcc.spec
}

build_mcu()
{
    set -e
    echo -e "\n***" installing ${MSP430MCU} "->" ${PREFIX}
    (
	cd ${MSP430MCU}
	MSP430MCU_ROOT=$(pwd) scripts/install.sh ${PREFIX}
    )
#
# ${BUILD_ROOT}/msp430mcu.files contains all files built so far.
# ie. all files built for binutils and gcc.  Its cummulative.
#
    ( cd $PREFIX ; find . -type f -o -type l) > ${BUILD_ROOT}/msp430mcu.files
}

package_mcu_deb()
{
    set -e
    VER=${MSP430MCU_VER}
    LAST_PATCH="$(last_patch msp430mcu-*.patch)"
    if [[ -z "${REL}" ]]; then
	DEB_VER=${VER}
    else
	DEB_VER=${VER}-${REL}${MSPGCC_VER}${LAST_PATCH}
    fi
    echo -e "\n***" debian archive: ${MSP430MCU} \-\> ${PACKAGES_DIR}
    (
	cd ${MSP430MCU}
	mkdir -p debian/DEBIAN debian/${DEB_DEST}
	rsync -a -m ../debian/${DEB_DEST}/ debian/${DEB_DEST}/
	(
	    cd debian/${DEB_DEST}
#
# remove all previously built files.   This leaves only those files we
# have explicilty built.
#
	    cat ${BUILD_ROOT}/msp430-gcc.files | xargs rm -rf
	    until find . -empty -exec rm -rf {} \; &> /dev/null
	    do : ; done
	)
	cat ../msp430mcu.control \
	    | sed 's/@version@/'${DEB_VER}'/' \
	    | sed 's/@architecture@/'${ARCH_TYPE}'/' \
	    > debian/DEBIAN/control
	fakeroot dpkg-deb --build debian .
	mv *.deb ${PACKAGES_DIR}
    )
}

package_mcu_rpm()
{
    VER=${MSP430MCU_VER}
    LAST_PATCH=$(last_patch msp430mcu-*.patch)
    RPM_VER=${VER}+${REL}${MSPGCC_VER}${LAST_PATCH}
    rpmbuild \
	-D "version ${RPM_VER}" \
	-D "release `date +%Y%m%d`" \
	-D "prefix ${PREFIX}" \
	-bb msp430mcu.spec
}

build_libc()
{
    set -e
    echo -e "\n***" building ${MSP430LIBC} "->" ${PREFIX}
    (
	PATH=${PREFIX}/bin:${PATH}
	echo -e -n "\n*** which msp430-gcc: "
	which msp430-gcc
	msp430-gcc --version
	cd ${MSP430LIBC}
	cd src
	make PREFIX=${PREFIX} ${MAKE_J}
	make PREFIX=${PREFIX} install
    )
    ( cd $PREFIX ; find . -type f -o -type l) > ${BUILD_ROOT}/msp430-libc.files
}

package_libc_deb()
{
    set -e
    VER=${MSP430LIBC_VER}
    LAST_PATCH="$(last_patch msp430-libc-*.patch)"
    if [[ -z "${REL}" ]]; then
	DEB_VER=${VER}
    else
	DEB_VER=${VER}-${REL}${MSPGCC_VER}${LAST_PATCH}
    fi
    echo -e "\n***" debian archive: ${MSP430LIBC} \-\> ${PACKAGES_DIR}
    (
	cd ${MSP430LIBC}
	mkdir -p debian/DEBIAN debian/${DEB_DEST}
	rsync -a -m ../debian/${DEB_DEST}/ debian/${DEB_DEST}/
	(
	    cd debian/${DEB_DEST}
	    cat ${BUILD_ROOT}/msp430mcu.files | xargs rm -rf
	    until find . -empty -exec rm -rf {} \; &> /dev/null
	    do : ; done
	)
	cat ../msp430-libc.control \
	    | sed 's/@version@/'${DEB_VER}'/' \
	    | sed 's/@architecture@/'${ARCH_TYPE}'/' \
	    > debian/DEBIAN/control
	fakeroot dpkg-deb --build debian .
	mv *.deb ${PACKAGES_DIR}
    )
}

package_libc_rpm()
{
    VER=${MSP430LIBC_VER}
    LAST_PATCH=$(last_patch msp430-libc-*.patch)
    RPM_VER=${VER}+${REL}${MSPGCC_VER}${LAST_PATCH}
    rpmbuild \
	-D "version ${RPM_VER}" \
	-D "release `date +%Y%m%d`" \
	-D "prefix ${PREFIX}" \
	-bb msp430-libc.spec
}

build_gdb()
{
    set -e
    echo -e "\n***" building ${GDB} "->" ${PREFIX}
    (
	cd ${GDB}
	../${GDB}/configure \
	    --prefix=${PREFIX} \
	    --target=msp430
	make ${MAKE_J}
	make install
#	rm -rf ${PREFIX}{/lib*/libiberty.a,/share/info,/share/locale,/share/gdb/syscalls}
	rm -rf ${PREFIX}{/lib*/libiberty.a,/share/locale,/share/gdb/syscalls}
	find ${PREFIX} -empty | xargs rm -rf
    )
}

package_gdb_deb()
{
    set -e
    VER=${GDB_VER}
    LAST_PATCH=$(last_patch msp430-gdb-*.patch)
    if [[ -z "${LAST_PATCH}" ]]; then
	LAST_PATCH=$(last_patch gdb-*.patch)
    fi
    DEB_VER=${VER}-${REL}${MSPGCC_VER}${LAST_PATCH}
    echo -e "\n***" debian archive: ${GDB} \-\> ${PACKAGES_DIR}
    (
	cd ${GDB}
	mkdir -p debian/DEBIAN debian/${DEB_DEST}
	cat ../msp430-gdb.control \
	    | sed 's/@version@/'${DEB_VER}'/' \
	    | sed 's/@architecture@/'${ARCH_TYPE}'/' \
	    > debian/DEBIAN/control
	rsync -a ../debian/${DEB_DEST}/ debian/${DEB_DEST}/
	(
	    cd debian/${DEB_DEST}
	    cat ${BUILD_ROOT}/msp430-libc.files | xargs rm -rf
	    find . -empty | xargs rm -rf
	)
	fakeroot dpkg-deb --build debian .
	mv *.deb ${PACKAGES_DIR}
    )
}

package_gdb_rpm()
{
    VER=${GDB_VER}
    LAST_PATCH=$(last_patch msp430-gdb-*.patch)
    RPM_VER=${VER}+${REL}${MSPGCC_VER}${LAST_PATCH}
    rpmbuild \
	-D "version ${RPM_VER}" \
	-D "release `date +%Y%m%d`" \
	-D "prefix ${PREFIX}" \
	-bb msp430-gdb.spec
}

package_dummy_deb()
{
    set -e
    echo -e "\n***" debian archive: msp430-45 \-\> ${PACKAGES_DIR}
    (
	mkdir -p tinyos
	cd tinyos
	mkdir -p debian/DEBIAN
	cat ../msp430-45.control \
	    | sed 's/@version@/'$(date +%Y%m%d)'/' \
	    | sed 's/@architecture@/'${ARCH_TYPE}'/' \
	    > debian/DEBIAN/control
	fakeroot dpkg-deb --build debian .
	mv *.deb ${PACKAGES_DIR}
    )
}

remove()
{
    for f in $@
    do
	if [ -a ${f} ]
	then
	    echo Removing ${f}
	    rm -rf $f
	fi
    done
}

case $1 in
    test)
	setup_deb
	download
#	patch_dirs
#	build_binutils
#	package_binutils_deb
#	build_gcc
#	package_gcc_deb
#	build_mcu
#	package_mcu_deb
#	build_libc
#	package_libc_deb
#	build_gdb
#	package_gdb_deb
	package_dummy_deb
	;;

    download)
	download
	patch_dirs
	;;

    clean)
	remove $(echo binutils-* gcc-* gdb-* mspgcc-* msp430-libc-2011* \
	    msp430mcu-* mpfr-* gmp-* mpc-* \
	    | fmt -1 | grep -v 'tar' | grep -v 'patch' | xargs)
	remove tinyos *.files debian fedora
	;;

    veryclean)
	remove binutils-* gcc-* gdb-* mspgcc-* msp430-libc-2011* \
	    msp430mcu-* mpfr-* gmp-* mpc-*
	remove tinyos *.patch *.files debian fedora packages
	;;

    deb)
        setup_deb
	download
	patch_dirs
	build_binutils
	package_binutils_deb
	build_gcc
	package_gcc_deb
	build_mcu
	package_mcu_deb
	build_libc
	package_libc_deb
	build_gdb
	package_gdb_deb
	package_dummy_deb
 	;;

    repo)
	setup_deb
	if [[ -z "${REPO_DEST}" ]]; then
	    REPO_DEST=${TINYOS_ROOT_DIR}/packaging/repo
	fi
	echo -e "\n*** Building Repository: [${CODENAME}] -> ${REPO_DEST}"
	echo -e   "*** Using packages from ${PACKAGES_DIR}\n"
	find ${PACKAGES_DIR} -iname "*.deb" -exec reprepro -b ${REPO_DEST} includedeb ${CODENAME} '{}' \;
	;;

    rpm)
        setup_rpm
	download
	patch_dirs
	build_binutils
	package_binutils_rpm
	build_gcc
	package_gcc_rpm
	build_mcu
	package_mcu_rpm
	build_libc
	package_libc_rpm
	build_gdb
	package_gdb_rpm
	;;

    local)
	setup_local
	download
	patch_dirs
	build_binutils
	build_mcu
	build_gcc
	build_libc
	build_gdb
	;;

    *)
	echo -e "\n./build.sh <target>"
	echo -e "    local | rpm | deb | repo | clean | veryclean | download"
esac
