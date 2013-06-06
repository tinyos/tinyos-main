#!/bin/bash
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


SOURCENAME=tinyos
SOURCEVERSION=2.1.2d
SOURCEDIRNAME=${SOURCENAME}-${SOURCEVERSION}
#PACKAGE_RELEASE=1
PREFIX=/opt
MAKE="make -j8"

download()
{
  mkdir -p ${SOURCEDIRNAME}
	cp -R ${TINYOS_ROOT_DIR}/apps ${SOURCEDIRNAME}/apps
	cp -R ${TINYOS_ROOT_DIR}/licenses ${SOURCEDIRNAME}/licenses
	cp -R ${TINYOS_ROOT_DIR}/support ${SOURCEDIRNAME}/support
	cp -R ${TINYOS_ROOT_DIR}/tos ${SOURCEDIRNAME}/tos
	cp ${TINYOS_ROOT_DIR}/README.tinyos ${SOURCEDIRNAME}
	cp ${TINYOS_ROOT_DIR}/release-notes.txt ${SOURCEDIRNAME}
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
BUILD_ROOT=$(pwd)
case $1 in
  test)
		installto
# 		cd ${BUILD_ROOT}
#		package_deb
    ;;

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
    setup_package_target ${SOURCENAME} ${SOURCEVERSION} ${PACKAGE_RELEASE}
    cd ${BUILD_ROOT}
    download
    cd ${BUILD_ROOT}
    installto
    cd ${BUILD_ROOT}
    package_deb
    cd ${BUILD_ROOT}
    cleaninstall
    ;;

  rpm)
    setup_package_target ${SOURCENAME} ${SOURCEVERSION} ${PACKAGE_RELEASE}
    cd ${BUILD_ROOT}
    download
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
    installto
    ;;
    
  tarball)
    cd ${BUILD_ROOT}
    download
    tar -cjf ${SOURCEDIRNAME}.tar.bz2 ${SOURCEDIRNAME}
    ;;

  *)
    echo -e "\n./build.sh <target>"
    echo -e "    local | rpm | deb | clean | veryclean | download | tarball"
esac

