#!/bin/bash
#
# make a package that contains current TinyOS source code.  This is built
# as a subset of the development tree.  For full code, see the git repository.
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

SOURCENAME=tinyos
SOURCEVERSION=2.1.3-devel
SOURCEDIRNAME=${SOURCENAME}-${SOURCEVERSION}
#PACKAGE_RELEASE=1
TIP=`git rev-parse --short HEAD`
PACKAGE_RELEASE=${TIP}
PREFIX=/opt
MAKE="make -j8"

download()
{
  mkdir -p ${SOURCEDIRNAME}
	cp -R ${TINYOS_ROOT_DIR}/apps ${SOURCEDIRNAME}/apps
	cp -R ${TINYOS_ROOT_DIR}/licenses ${SOURCEDIRNAME}/licenses
	cp -R ${TINYOS_ROOT_DIR}/support ${SOURCEDIRNAME}/support
	cp -R ${TINYOS_ROOT_DIR}/tools ${SOURCEDIRNAME}/tools
	cp -R ${TINYOS_ROOT_DIR}/tos ${SOURCEDIRNAME}/tos
	cp ${TINYOS_ROOT_DIR}/README.tinyos ${SOURCEDIRNAME}
	cp ${TINYOS_ROOT_DIR}/release-notes.txt ${SOURCEDIRNAME}
	cp ${TINYOS_ROOT_DIR}/11_Release_Notes ${SOURCEDIRNAME}
}

installto()
{
  mkdir -p ${INSTALLDIR}/opt
  cp -R ${SOURCEDIRNAME} ${INSTALLDIR}/opt/
}

package_deb(){
  package_deb_from ${INSTALLDIR} ${SOURCEVERSION}-${PACKAGE_RELEASE} tinyos.control nopostinst noprerm all
}

package_rpm(){
  package_rpm_from ${INSTALLDIR} ${SOURCEVERSION} ${PACKAGE_RELEASE} ${PREFIX} tinyos.spec
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

#main funcition
case $1 in
  test)
      download
#     installto
#     package_deb
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
    installto
    ;;

  tarball)
    download
    tar -cjf ${SOURCEDIRNAME}.tar.bz2 ${SOURCEDIRNAME}
    ;;

  *)
    echo -e "\n./build.sh <target>"
    echo -e "    local | rpm | deb | clean | veryclean | download | tarball"
esac
