#!/bin/bash
#
# BUILD_ROOT is assumed to be the same directory as the build.sh file.
#
# set TINYOS_ROOT_DIR to the head of the tinyos source tree root.
# used to find default PACKAGES_DIR.
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

BUILD_ROOT=$(pwd)
: ${POST_VER:=-tinyos}

DEB_DEST=usr
CODENAME=stretch
MAKE_J=-j1

if [[ -z "${TINYOS_ROOT_DIR}" ]]; then
    TINYOS_ROOT_DIR=$(pwd)/../..
fi
echo -e "\n*** TINYOS_ROOT_DIR: $TINYOS_ROOT_DIR"
echo      "*** Destination: ${DEB_DEST}"

NESC_VER=1.3.6
NESC=nesc-${NESC_VER}

setup_deb()
{
    ARCH_TYPE=$(dpkg-architecture -qDEB_HOST_ARCH)
    PREFIX=${BUILD_ROOT}/${NESC}/debian/${DEB_DEST}
    if [[ -z "${PACKAGES_DIR}" ]]; then
	PACKAGES_DIR=${BUILD_ROOT}/packages
    fi
    mkdir -p ${PACKAGES_DIR}
}


setup_rpm()
{
    PREFIX=${BUILD_ROOT}/${NESC}/fedora/${DEB_DEST}
}


setup_local()
{
    mkdir -p ${TINYOS_ROOT_DIR}/local
    ${PREFIX:=${TINYOS_ROOT_DIR}/local}
}


download()
{
    echo -e "\n*** Downloading ... ${NESC}"
    [[ -a ${NESC}.tar.gz ]] \
	|| wget https://github.com/tinyos/nesc/archive/v${NESC_VER}.tar.gz -O ${NESC}.tar.gz
}

build()
{
    echo Unpacking ${NESC}.tar.gz
    rm -rf ${NESC}
    tar -xzf ${NESC}.tar.gz
    set -e
    (
	cd ${NESC}
	./Bootstrap
	./configure --prefix=${PREFIX}
	make ${MAKE_J}
	make install-strip
    )
}

package_deb()
{
    VER=${NESC_VER}
    DEB_VER=${VER}${POST_VER}
    echo -e "\n***" debian archive: ${NESC} \-\> ${PACKAGES_DIR}
    cd ${NESC}
    mkdir -p debian/DEBIAN debian/${DEB_DEST}
    find debian/${DEB_DEST}/bin/ -type f \
	| xargs perl -i -pe 's#'${PREFIX}'#/'${DEB_DEST}'#'
    cat ../nesc.control \
	| sed 's/@version@/'${DEB_VER}'/' \
	| sed 's/@architecture@/'${ARCH_TYPE}'/' \
	> debian/DEBIAN/control
    fakeroot dpkg-deb --build debian .
    mv *.deb ${PACKAGES_DIR}
}


package_rpm()
{
    echo Packaging ${NESC}
    find fedora/usr/bin/ -type f \
	| xargs perl -i -pe 's#'${PREFIX}'#/usr#'
    rpmbuild \
	-D "version ${NESC_VER}" \
	-D "release `date +%Y%m%d`" \
	-D "prefix ${PREFIX}" \
	-bb nesc.spec
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
    test)
	setup_deb
	package_deb
	;;

    download)
        download
	;;

    build)
	build
	;;

    clean)
	remove ${NESC}
	;;

    veryclean)
	remove ${NESC}{,.tar.gz} packages
	;;

    deb)
	setup_deb
	download
	build
	package_deb
	;;

    sign)
        setup_deb
        if [[ -z "$2" ]]; then
            dpkg-sig -s builder ${PACKAGES_DIR}/*
        else
            dpkg-sig -s builder -k $2 ${PACKAGES_DIR}/*
        fi
        ;;

    rpm)
	setup_rpm
	download
	build
	package_rpm
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

    local)
	setup_local
	download
	build
	;;

    *)
	echo -e "\n./build.sh <target>"
	echo -e "    local | rpm | deb | sign | repo | clean | veryclean | download"
esac
