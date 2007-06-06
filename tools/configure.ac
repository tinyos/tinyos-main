#!/bin/sh
# Copyright (c) 2005 Intel Corporation
# All rights reserved.
#
# This file is distributed under the terms in the attached INTEL-LICENSE     
# file. If you do not find these files, copies can be found by writing to
# Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
# 94704.  Attention:  Intel License Inquiry.

dnl -*- m4 -*-

# force autoconf 2.5 on Debian systems
AC_PREREQ(2.50)

AC_INIT(tinyos-tools, 1.2.1)
AC_CONFIG_AUX_DIR(config-aux)
AM_INIT_AUTOMAKE
AC_CANONICAL_HOST

AC_PROG_CC
AC_PROG_CXX
AC_PROG_RANLIB

AC_PATH_PROG(pathperl, perl)
if test -z "$pathperl" ; then
  AC_MSG_ERROR(I can't find perl); 
fi

AC_PATH_PROG(pathpython, python)
if test -z "$pathpython" ; then
  AC_MSG_ERROR(I can't find python); 
fi

if test -z "$NESCC_PREFIX"; then
  AC_PATH_PROG(pathnescc, nescc)
  if test -z "$pathnescc"; then
    AC_MSG_ERROR(I can't find nescc)
  else
    NESCC_PREFIX=`dirname "$pathnescc"`
    NESCC_PREFIX=`dirname "$NESCC_PREFIX"`
  fi
fi
nescc_prefix=`(cd $NESCC_PREFIX;pwd)`
AC_SUBST(nescc_prefix)


if test -z "$DEFAULT_TARGET"; then
  DEFAULT_TARGET=mica
fi
default_target=$DEFAULT_TARGET
AC_MSG_NOTICE(Default ncc build target is $default_target)
AC_MSG_NOTICE(...but using a tos/.default-platform file is a better choice)
AC_SUBST(default_target)

if test -z "$TOSDIR"; then
  if test -d ../tos; then
    TOSDIR=../tos
  elif test -d ../../tos; then
    TOSDIR=../../tos
  elif test -d $HOME/nest/tos; then
    TOSDIR=$HOME/nest/tos
  else
    AC_MSG_ERROR(I can't find the tos directory);
  fi
fi
TOSDIR=`(cd $TOSDIR;pwd)`
AC_MSG_NOTICE(TinyOS directory is $TOSDIR)
AC_SUBST(TOSDIR)

AC_MSG_CHECKING(for cygwin)
case $host in
  *-*-cygwin*)
    AC_MSG_RESULT(yes)
    JNIPREFIX=
    JNISUFFIX=dll
    JNIVERSIONS=.
    INSTALLJNI="install --group=SYSTEM"
    CYGWIN=yes
    ;;
  *)
    JNIPREFIX=lib
    JNISUFFIX=so
    JNIVERSIONS="-32. -64."
    INSTALLJNI="install"
    AC_MSG_RESULT(no)
esac

AM_CONDITIONAL([CYGWIN], [test "$CYGWIN"])

AC_MSG_CHECKING(for JDK location)
JAVAC_DIR=`/bin/sh tinyos/misc/tos-locate-jre --javac`
if test $? -ne 0; then
  AC_ERROR(java not found)
fi
JDK=`dirname "$JAVAC_DIR"`
AC_MSG_RESULT($JDK)

function jnimap {
  for v in $JNIVERSIONS; do
    echo -n "${JNIPREFIX}$1$v$JNISUFFIX "
  done
}

GETENVLIB=`jnimap getenv`
TOSCOMMLIB=`jnimap toscomm`

AC_SUBST(GETENVLIB)
AC_SUBST(TOSCOMMLIB)
AC_SUBST(JDK)
AC_SUBST(INSTALLJNI)
AC_SUBST(JNIPREFIX)
AC_SUBST(JNISUFFIX)

AC_CONFIG_SUBDIRS(platforms/mica/uisp)

AC_OUTPUT(
	Makefile
	platforms/Makefile
	platforms/mica/Makefile
	platforms/mica/cc1000-channelgen/Makefile
	platforms/msp430/Makefile
	platforms/msp430/motelist/Makefile
	platforms/msp430/pybsl/Makefile
	platforms/msp430/pybsl/tos-bsl.1
	platforms/msp430/pybsl/serial/Makefile
	tinyos/Makefile
	tinyos/java/Makefile
	tinyos/java/env/Makefile
	tinyos/java/serial/Makefile
	tinyos/misc/tos-ident-flags
	tinyos/misc/tos-install-jni
	tinyos/misc/tos-set-symbols
	tinyos/misc/tos-write-image
	tinyos/misc/tos-storage-at45db
	tinyos/misc/tos-storage-stm25p
	tinyos/misc/Makefile
	tinyos/ncc/Makefile
	tinyos/ncc/mig
	tinyos/ncc/ncc
	tinyos/ncc/ncg
	tinyos/ncc/nesdoc
	tinyos/ncc/nesdoc-py/Makefile
)
