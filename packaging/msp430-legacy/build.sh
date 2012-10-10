#!/bin/bash

BINUTILS_VER=2.17
BINUTILS=binutils-${BINUTILS_VER}
GCC_VER=3.2.3
GCC_CORE=gcc-core-${GCC_VER}
GCC=gcc-${GCC_VER}
MSPGCC_VER=20060801cvs
MSPGCC=mspgcc-cvs

if [[ "$1" == deb ]]
then
    ARCH_TYPE=$(dpkg-architecture -qDEB_HOST_ARCH)
    PREFIX=$(pwd)/debian/usr
    PACKAGES_DIR=$(pwd)/../../../../packages/debian/${ARCH_TYPE}
    mkdir -p ${PACKAGES_DIR}
    mkdir -p ${PACKAGES_DIR/${ARCH_TYPE}/all}
fi

if [[ "$1" == rpm ]]
then
    PREFIX=$(pwd)/fedora/usr
fi

: ${PREFIX:=$(pwd)/../../../../local}

download()
{
    [[ -a ${BINUTILS}a.tar.bz2 ]] \
	|| wget http://ftp.gnu.org/gnu/binutils/${BINUTILS}a.tar.bz2
    [[ -a gcc-core-${GCC_VER}.tar.gz ]] \
	|| wget http://ftp.gnu.org/gnu/gcc/gcc-${GCC_VER}/gcc-core-${GCC_VER}.tar.gz
    [[ -a mspgcc-cvs.tar.gz ]] \
	|| http://tinyos.stanford.edu/tinyos/toolchain/repo/mspgcc-cvs.tar.gz
}

build_binutils()
{
    echo Unpacking ${BINUTILS}a.tar.bz2
    rm -rf ${BINUTILS}
    tar -xjf ${BINUTILS}a.tar.bz2
    set -e
    (
	cd ${BINUTILS}
	perl -i.orig \
	    -pe 's/define (LEX_DOLLAR) 0/undef	$1/' \
	    gas/config/tc-msp430.h
	./configure \
	    --prefix=${PREFIX} \
	    --target=msp430 \
	    --program-prefix=msp430- \
	    --disable-werror
	make
	make install
	rm -rf ${PREFIX}{/info,/lib/libiberty.a,/share/locale}
	find ${PREFIX} -empty | xargs rm -rf
    )
    ( cd $PREFIX ; find . -type f ) > msp430-binutils.files
}

package_binutils()
{
    set -e
    (
	VER=${BINUTILS_VER}
	cd ${BINUTILS}
	mkdir -p debian/DEBIAN
	cat ../msp430-binutils.control \
	    | sed 's/@version@/'${VER}-$(date +%Y%m%d)'/' \
	    | sed 's/@architecture@/'${ARCH_TYPE}'/' \
	    > debian/DEBIAN/control
	rsync -a ../debian/usr debian
	fakeroot dpkg-deb --build debian \
	    ${PACKAGES_DIR}/msp430-binutils-tinyos-legacy-${VER}.deb
    )
}

package_binutils_rpm()
{
    VER=${BINUTILS_VER}
    rpmbuild \
	-D "version ${VER}" \
	-D "release `date +%Y%m%d`" \
	-D "prefix ${PREFIX}" \
	-bb msp430-binutils.spec
}

build_gcc()
{
    echo Unpacking ${MSPGCC}.tar.gz
    rm -rf ${MSPGCC}
    tar -xzf ${MSPGCC}.tar.gz
    echo Unpacking ${GCC_CORE}.tar.gz
    rm -rf ${GCC}
    tar -xzf ${GCC_CORE}.tar.gz

    set -e
    (
	PATH=${PREFIX}/bin:${PATH}
	cd ${GCC}
	cp -a ../${MSPGCC}/gcc/gcc-3.3/* .
	./configure \
	    --prefix=${PREFIX} \
	    --target=msp430 \
	    --program-prefix=msp430-
	CPPFLAGS=-D_FORTIFY_SOURCE=0 make
	make install
	rm -rf ${PREFIX}{/info,/lib/libiberty.a,/share/locale}
	( cd ${PREFIX} ; find man | grep -v msp430 | xargs rm -rf )
	find ${PREFIX} -empty | xargs rm -rf
    )
    ( cd $PREFIX ; find . -type f ) > msp430-gcc.files
}

package_gcc_deb()
{
    set -e
    (
	VER=${GCC_VER}
	cd ${GCC}
	mkdir -p debian/DEBIAN
	cat ../msp430-gcc.control \
	    | sed 's/@version@/'${VER}-$(date +%Y%m%d)'/' \
	    | sed 's/@architecture@/'${ARCH_TYPE}'/' \
	    > debian/DEBIAN/control
	rsync -a ../debian/usr debian
	(
	    cd debian/usr
	    cat ../../../msp430-binutils.files | xargs rm -rf
	    find . -empty | xargs rm -rf
	)
	fakeroot dpkg-deb --build debian \
	    ${PACKAGES_DIR}/msp430-gcc-tinyos-legacy-${VER}.deb
    )
}

package_gcc_rpm()
{
    VER=${GCC_VER}
    rpmbuild \
	-D "version ${VER}" \
	-D "release `date +%Y%m%d`" \
	-D "prefix ${PREFIX}" \
	-bb msp430-gcc.spec
}

build_libc()
{
    set -e
    (
	PATH=${PREFIX}/bin:${PATH}
	cd ${MSPGCC}/msp430-libc/src

	(
	    cd ../include/msp430
	    patch -p0 < ../../../../adc12.patch
	)

	[[ -d msp1 ]] || mkdir msp1
	[[ -d msp2 ]] || mkdir msp2
	perl -i.orig \
	    -pe 's{^(prefix\s*=\s*)(.*)}{${1}'"$PREFIX"'}' \
	    Makefile
	make
	make install

	(
	    cd ../include/msp430
	    patch -R -p0 < ../../../../adc12.patch
	)
    )
}

package_libc_deb()
{
    set -e
    (
	VER=${MSPGCC_VER}
	cd ${MSPGCC}
	rsync -a -m ../debian/usr debian
	(
	    cd debian/usr
	    cat ../../../msp430-gcc.files | xargs rm -rf
	    until find . -empty -exec rm -rf {} \; &> /dev/null
	    do : ; done
	)
	mkdir -p debian/DEBIAN
	cat ../msp430-libc.control \
	    | sed 's/@version@/'${VER}-$(date +%Y%m%d)'/' \
	    | sed 's/@architecture@/'${ARCH_TYPE}'/' \
	    > debian/DEBIAN/control
	fakeroot dpkg-deb --build debian \
	    ${PACKAGES_DIR}/msp430-libc-tinyos-legacy-${VER}.deb
    )
}

package_libc_rpm()
{
    VER=${MSPGCC_VER}
    rpmbuild \
	-D "version ${VER}" \
	-D "release `date +%Y%m%d`" \
	-D "prefix ${PREFIX}" \
	-bb msp430-libc.spec
}

package_dummy_deb()
{
    set -e
    (
	mkdir -p tinyos
	cd tinyos
	mkdir -p debian/DEBIAN
	cat ../msp430-tinyos.control \
	    | sed 's/@version@/'$(date +%Y%m%d)'/' \
	    > debian/DEBIAN/control
	fakeroot dpkg-deb --build debian \
	    ${PACKAGES_DIR/${ARCH_TYPE}/all}/msp430-tinyos-legacy.deb
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
    download)
	download
	;;

    clean)
	remove ${BINUTILS} ${GCC} ${MSPGCC} tinyos *.files debian fedora
	;;

    veryclean)
	remove {${BINUTILS},${GCC},${GCC_CORE}}{,.tar.gz,a.tar.bz2}
	remove tinyos *.files debian fedora
	remove ${MSPGCC}
	;;

    deb)
	download
	build_binutils
	package_binutils_deb
	build_gcc
	package_gcc_deb
	build_libc
	package_libc_deb
	package_dummy_deb
	;;

    rpm)
	download
	build_binutils
	package_binutils_rpm
	build_gcc
	package_gcc_rpm
	build_libc
	package_libc_rpm
	;;

    *)
	download
	build_binutils
	build_gcc
	build_libc
	;;
esac
