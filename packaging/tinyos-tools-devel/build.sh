#!/bin/bash
#
# Builds against the trunk.  PACKAGE_RELEASE gets set to version number
# concatenated with the SHA of this branch's tip.
#
# The tinyos-tools package will pick up various tool scripts and binaries
# built from the tinyos source tree.  This makes the tinyos-tools package
# dependent on the current state of the tree.
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
# PACKAGES_DIR	where packages get stashed.  Defaults to ${BUILD_ROOT}/packages
# REPO_DEST	Where the repository is being built (${TINYOS_ROOT_DIR}/packaging/repo)
# DEB_DEST	final home once installed.
# CODENAME	which part of the repository to place this build in.
#
# REPO_DEST	must contain a conf/distributions file for reprepro to work
#		properly.   Examples of reprepo configuration can be found in
#               ${TINYOS_ROOT_DIR}/packaging/repo/conf.
#

COMMON_FUNCTIONS_SCRIPT=../functions-build.sh
source ${COMMON_FUNCTIONS_SCRIPT}

BUILD_ROOT=$(pwd)
CODENAME=stretch

SOURCENAME=tinyos-tools-devel
SOURCEVERSION=1.5.1
SOURCEDIRNAME=${SOURCENAME}_${SOURCEVERSION}
TIP=`git rev-parse --short HEAD`
PACKAGE_RELEASE=${TIP}
#PACKAGE_RELEASE=1
PREFIX=/usr
MAKE="make -j1"

download()
{
  mkdir -p ${SOURCEDIRNAME}
  cp -R ${TINYOS_ROOT_DIR}/tools ${SOURCEDIRNAME}
  cp -R ${TINYOS_ROOT_DIR}/licenses ${SOURCEDIRNAME}
  ln -s ${TINYOS_ROOT_DIR}/tos ${SOURCEDIRNAME}/tos
}

build()
{
  set -e
  (
    cd ${SOURCEDIRNAME}/tools
    ./Bootstrap
    ./configure --prefix=${PREFIX}
    ${MAKE}
  )
}

installto()
{
  set -e
  (
    cd ${SOURCEDIRNAME}/tools
    ${MAKE} DESTDIR=${INSTALLDIR} install
  )
}

package_deb(){
  package_deb_from ${INSTALLDIR} ${SOURCEVERSION}-${PACKAGE_RELEASE} tinyos-tools.control tinyos-tools.postinst
}

package_rpm(){
  package_rpm_from ${INSTALLDIR} ${SOURCEVERSION} ${PACKAGE_RELEASE} ${PREFIX} tinyos-tools.spec
}

cleanbuild(){
  remove ${SOURCEDIRNAME}
}

cleandownloaded(){
  remove ${SOURCEFILENAME} ${PATCHES}
}

cleaninstall(){
  remove ${INSTALLDIR}
}

#main function
case $1 in
  test)
    setup_package_target ${SOURCENAME} ${SOURCEVERSION} ${PACKAGE_RELEASE}
    download
#    installto
#    package_deb
    ;;

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

  deb)
    # sets up INSTALLDIR, which package_deb uses
    setup_package_target ${SOURCENAME} ${SOURCEVERSION} ${PACKAGE_RELEASE}
    download
    build
    installto
    package_deb
    cleaninstall
    ;;

  sign)
    setup_package_target ${SOURCENAME} ${SOURCEVERSION} ${PACKAGE_RELEASE}
    if [[ -z "$2" ]]; then
        dpkg-sig -s builder ${PACKAGES_DIR}/*
    else
        dpkg-sig -s builder -k $2 ${PACKAGES_DIR}/*
    fi
    ;;

  rpm)
    setup_package_target ${SOURCENAME} ${SOURCEVERSION} ${PACKAGE_RELEASE}
    download
    build
    installto
    package_rpm
    cleaninstall
    ;;

  repo)
    setup_package_target ${SOURCENAME} ${SOURCEVERSION} ${PACKAGE_RELEASE}
    if [[ -z "${REPO_DEST}" ]]; then
      REPO_DEST=${TINYOS_ROOT_DIR}/packaging/repo
    fi
    echo -e "\n*** Building Repository: [${CODENAME}] -> ${REPO_DEST}"
    echo -e   "*** Using packages from ${PACKAGES_DIR}\n"
    find ${PACKAGES_DIR} -iname "*.deb" -exec reprepro -b ${REPO_DEST} includedeb ${CODENAME} '{}' \;
    ;;

  local)
    setup_local_target
    download
    build
    installto
    ;;

  tarball)
    download
    tar -cjf ${SOURCEDIRNAME}.tar.bz2 ${SOURCEDIRNAME}
    ;;

  *)
    echo -e "\n./build.sh <target>"
    echo -e "    local | rpm | deb | sign | repo | clean | veryclean | download | tarball"
esac
