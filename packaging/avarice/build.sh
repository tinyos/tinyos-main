#!/bin/bash

AVARICE_VER=2.11
AVARICE=avarice-${AVARICE_VER}

if [[ "$1" == deb ]]
then
    ARCH_TYPE=$(dpkg-architecture -qDEB_HOST_ARCH)
    PREFIX=$(pwd)/${AVARICE}/debian/usr
    PACKAGES_DIR=$(pwd)/../../../../packages/${ARCH_TYPE}
    mkdir -p ${PACKAGES_DIR}
fi

if [[ "$1" == rpm ]]
then
    PREFIX=$(pwd)/${NESC}/fedora/usr
fi

: ${PREFIX:=$(pwd)/../../../../local}

download()
{
    [[ -a ${AVARICE}.tar.bz2 ]] \
	|| wget http://sourceforge.net/projects/avarice/files/avarice/${AVARICE}/${AVARICE}.tar.bz2
}

build_avarice()
{
    echo Unpacking ${AVARICE}.tar.bz2
    rm -rf ${AVARICE}
    tar -xjf ${AVARICE}.tar.bz2
    set -e
    (
	cd ${AVARICE}
	LIBS=-ldl ./configure \
	    --prefix=${PREFIX}
	make
	make install
    )
}

package_avarice_deb()
{
    set -e
    (
	VER=${AVARICE_VER}
	cd ${AVARICE}
	mkdir -p debian/DEBIAN
	cat ../avarice.control \
	    | sed 's/@version@/'${VER}-$(date +%Y%m%d)'/' \
	    | sed 's/@architecture@/'${ARCH_TYPE}'/' \
	    > debian/DEBIAN/control
	fakeroot dpkg-deb --build debian \
	    ${PACKAGES_DIR}/avarice-tinyos-${VER}.deb
    )
}

package_avarice_rpm()
{
    echo Packaging ${AVARICE}
    rpmbuild \
	-D "version ${AVARICE_VER}" \
	-D "release `date +%Y%m%d`" \
	-D "prefix ${PREFIX}/.." \
	-bb avarice.spec
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
	remove ${AVARICE} fedora
	;;

    veryclean)
	remove ${AVARICE}{,.tar.bz2} fedora
	;;

    deb)
	download
	build_avarice
	package_avarice_deb
	;;

    rpm)
	download
	build_avarice
	package_avarice_rpm
	;;

    *)
	download
	build_avarice
	;;
esac
