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

#default variables: overridable in build.sh
DATE=`date +%Y%m%d`
PACKAGE_RELEASE=${DATE}
if [[ -z "${TINYOS_ROOT_DIR}" ]]; then
	TINYOS_ROOT_DIR=$(pwd)/../..
fi

##parameters: 
#$1: package name
#$2: package version
#$3: package release
setup_package_target(){
	INSTALLDIR=${BUILD_ROOT}/${1}_${2}-${3}
	if [[ -z "${PACKAGES_DIR}" ]]; then
		PACKAGES_DIR=${BUILD_ROOT}/packages
	fi
	echo      "*** Install Directory ${INSTALLDIR}"
	echo      "*** Debian package Directory ${PACKAGES_DIR}"
}

setup_local_target()
{
	if [[ -z "${DESTDIR}" ]]; then
		INSTALLDIR=${TINYOS_ROOT_DIR}/local
	else
		INSTALLDIR=${DESTDIR}
	fi
	echo      "*** Install Directory ${INSTALLDIR}"
}


check_download()
{
	for filename in $@; do
		if ! [ -f $filename ]; then
			return 1
		fi
	done
	return 0
}

##parameters: 
#$1: directory
#$2: version
#$3: control file (default: debcontrol)
#$4: postinst file (default: debpostinst)
#$5: prerm file (default: debprerm)
#$6: force architecture
package_deb_from()
{
	if [ $6 ]; then
		ARCH_TYPE=$6
	else
		ARCH_TYPE=$(dpkg-architecture -qDEB_HOST_ARCH)
	fi
	install -d $1/DEBIAN
	#set up package control files
	if [ $3 ]; then 
		DEBCONTROL=$3
	else
		DEBCONTROL=${BUILD_ROOT}/debcontrol
	fi
	if [ $4 ]; then 
		DEBPOSTINST=$4
	else
		DEBPOSTINST=${BUILD_ROOT}/debpostinst
	fi
	if [ $5 ]; then 
		DEBPRERM=$5
	else
		DEBPRERM=${BUILD_ROOT}/debprerm
	fi
	#copy postinst/prerm script to its place
	if [ -f ${DEBPOSTINST} ]; then
		echo POSTINST ${DEBPOSTINST}
		cp ${DEBPOSTINST} ${1}/DEBIAN/postinst
		chmod 755 ${1}/DEBIAN/postinst
	fi
	if [ -f ${DEBPRERM} ]; then
		echo PRERM ${DEBPRERM}
		cp ${DEBPRERM} ${1}/DEBIAN/prerm
		chmod 755 ${1}/DEBIAN/prerm
	fi
	#set up version numbers, architecture
	sed "s/%{version}/${2}/g" ${DEBCONTROL}|\
		sed "s/%{architecture}/${ARCH_TYPE}/g">\
		${1}/DEBIAN/control
	#create pkg
	fakeroot dpkg-deb --build ${1}
	#create the pkg directoy
	install -d ${PACKAGES_DIR}
	oldfilename=`basename ${1}`
	newfilename="${oldfilename}_${ARCH_TYPE}"
	#move and rename to the package directory
	mv ${oldfilename}.deb ${PACKAGES_DIR}/${newfilename}.deb
}

##parameters: 
#$1: directory
#$2: version
#$3: release
#$4: prefix
#$5: spec file (default: rpm.spec)
package_rpm_from()
{
  if [ $5 ]; then 
		RPMSPEC=$5
	else
		RPMSPEC=${BUILD_ROOT}/rpm.spec
	fi
	rpmbuild  \
		-D "version ${2}" \
		-D "release ${3}" \
		-D "sourcedir ${1}/${4}" \
		-bb ${RPMSPEC}
}

remove()
{
  for f in $@
  do
    if [[ -a ${f} ]]
    then
      echo Removing ${f}
      /bin/rm -rf $f
    fi
  done
}

