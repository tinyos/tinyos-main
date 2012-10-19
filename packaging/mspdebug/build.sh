#!/bin/bash

# Env variables used....
#
# TOSROOT	head of the tinyos source tree root.  Used for base of default repo
# PACKAGES_DIR	where packages get stashed.  Defaults to ${BUILD_ROOT}/packages
# REPO_DEST	Where the repository is being built (defaults to ${TOSROOT}/tools/repo)
# DEB_DEST	final home once installed.
# CODENAME	which part of the repository to place this build in.
#
# REPO_DEST	must contain a conf/distributions file for reprepro to work
#		properly.   One can be copied from $(TOSROOT)/tools/repo/conf.
#
# we use opt for these tools to avoid conflicting with placement from normal
# distribution paths (debian or ubuntu repositories).
#

BUILD_ROOT=$(pwd)
: ${POST_VER:=-tinyos}

DEB_DEST=usr
CODENAME=squeeze
MAKE_J=-j8

if [[ -z "${TOSROOT}" ]]; then
    TOSROOT=$(pwd)/../../../..
fi
echo -e "\n*** TOSROOT: $TOSROOT"
echo "*** Destination: ${DEB_DEST}"

MSPDEBUG_VER=0.20
MSPDEBUG=mspdebug-${MSPDEBUG_VER}

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
    mkdir -p ${TOSROOT}/local
    ${PREFIX:=${TOSROOT}/local}
}


download()
{
    echo -e "\n*** Downloading ... ${MSPDEBUG}"
    [[ -a ${MSPDEBUG}.tar.gz ]] \
	|| wget http://sourceforge.net/projects/mspdebug/files/${MSPDEBUG}.tar.gz
}

build_mspdebug()
{
    echo Unpacking ${MSPDEBUG}.tar.gz
    rm -rf ${MSPDEBUG}
    tar xzf ${MSPDEBUG}.tar.gz
    set -e
    (
	cd ${MSPDEBUG}
	make ${MAKE_J}
	make install PREFIX=${PREFIX}
    )
}

package_mspdebug_deb()
{
    set -e
    (
	VER=${MSPDEBUG_VER}
	DEB_VER=${VER}${POST_VER}
	echo -e "\n***" debian archive: ${MSPDEBUG}${POST_VER}
	mkdir -p debian/DEBIAN debian/${DEB_DEST}
	cat mspdebug.control \
	    | sed 's/@version@/'${DEB_VER}'/' \
	    | sed 's/@architecture@/'${ARCH_TYPE}'/' \
	    > debian/DEBIAN/control
	fakeroot dpkg-deb --build debian .
	mv *.deb ${PACKAGES_DIR}
    )
}

package_mspdebug_rpm()
{
    echo Packaging ${MSPDEBUG}
    rpmbuild \
	-D "version ${MSPDEBUG_VER}" \
	-D "release `date +%Y%m%d`" \
	-D "prefix ${PREFIX}/.." \
	-bb mspdebug.spec
}

remove()
{
    for f in $@
    do
	if [[ -a ${f} ]]
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
	remove ${MSPDEBUG} debian fedora
	;;

    veryclean)
	remove mspdebug-* debian fedora packages
	;;

    deb)
	setup_deb
	download
	build_mspdebug
	package_mspdebug_deb
	;;

    rpm)
	setup_rpm
	download
	build_mspdebug
	package_mspdebug_rpm
	;;

    local)
	setup_local
	download
	build_mspdebug
	;;

    *)
	echo -e "\n./build.sh <target>"
	echo -e "    local | rpm | deb | clean | veryclean | download"
esac
