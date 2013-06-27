#!/bin/bash

AVRDUDE_VER=5.10
AVRDUDE=avrdude-${AVRDUDE_VER}

if [[ "$1" == deb ]]
then
    ARCH_TYPE=$(dpkg-architecture -qDEB_HOST_ARCH)
    PREFIX=$(pwd)/${AVRDUDE}/debian/usr
    PACKAGES_DIR=$(pwd)/../../../../packages/debian/${ARCH_TYPE}
    mkdir -p ${PACKAGES_DIR}
fi

if [[ "$1" == rpm ]]
then
    PREFIX=$(pwd)/${NESC}/fedora/usr
fi

: ${PREFIX:=$(pwd)/../../../../local}

download()
{
    [[ -a ${AVRDUDE}.tar.gz ]] \
	|| wget http://download.savannah.gnu.org/releases/avrdude/${AVRDUDE}.tar.gz
}

build_avrdude()
{
    echo Unpacking ${AVRDUDE}.tar.gz
    rm -rf ${AVRDUDE}
    tar -xzf ${AVRDUDE}.tar.gz
    set -e
    (
	cd ${AVRDUDE}
	sed -i -e 's|-DCONFIG_DIR=\\"$(sysconfdir)\\"|-DCONFIG_DIR=\\"/etc\\"|' Makefile.{am,in}
	./configure \
	    --prefix=${PREFIX} \
	    --sysconfdir=${PREFIX}/../etc
	make
	make install
    )
}

package_avrdude_deb()
{
    set -e
    (
	VER=${AVRDUDE_VER}
	cd ${AVRDUDE}
	mkdir -p debian/DEBIAN
	cat ../avrdude.control \
	    | sed 's/@version@/'${VER}-$(date +%Y%m%d)'/' \
	    | sed 's/@architecture@/'${ARCH_TYPE}'/' \
	    > debian/DEBIAN/control
	fakeroot dpkg-deb --build debian \
	    ${PACKAGES_DIR}/avrdude-tinyos-${VER}.deb
    )
}

package_avrdude_rpm()
{
    echo Packaging ${AVRDUDE}
    rpmbuild \
	-D "version ${AVRDUDE_VER}" \
	-D "release `date +%Y%m%d`" \
	-D "prefix ${PREFIX}/.." \
	-bb avrdude.spec
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
	remove ${AVRDUDE} fedora
	;;

    veryclean)
	remove ${AVRDUDE}{,.tar.gz} fedora
	;;

    deb)
	download
	build_avrdude
	package_avrdude_deb
	;;

    rpm)
	download
	build_avrdude
	package_avrdude_rpm
	;;

    *)
	download
	build_avrdude
	;;
esac
