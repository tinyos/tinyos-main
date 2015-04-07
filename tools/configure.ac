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

AC_INIT(tinyos-tools, 2.2.0)
AC_CONFIG_AUX_DIR(config-aux)
AM_INIT_AUTOMAKE(subdir-objects)
AC_CANONICAL_HOST

AC_PROG_CC
AC_PROG_CXX
AC_PROG_RANLIB

if test "$CXX" = no || test "$$CXX:$GXX" = "g++"; then
  AC_MSG_ERROR([No C++ compiler found])
fi

m4_include([m4/python.m4])
AM_PATH_PYTHON([3.0],,,3)
AM_PATH_PYTHON([2.5])

AC_PATH_PROG(pathperl, perl)
if test -z "$pathperl" ; then
  AC_MSG_ERROR(I can't find perl);
fi

AC_PATH_PROGS(pathpython, [python2 python2.7 python2.6 python2.5 python])
if test -z "$pathpython" ; then
  AC_MSG_ERROR(I can't find python);
fi

AC_PATH_PROGS(pathpython3, [python3 python3.5 python3.4 python3.3 python3.2 python3.1 python3.0])
if test -z "$pathpython3" ; then
  AC_MSG_ERROR(I can't find python3);
fi

AC_PATH_PROGS(pathpython_config, [python$PYTHON_VERSION-config])
if test -z "$pathpython_config" ; then
  AC_MSG_NOTICE(I can't find python$PYTHON_VERSION-config. python$PYTHON_VERSION-config is required for TOSSIM)
fi

AC_PATH_PROGS(pathdot, [dot])
if test -z "$pathdot"; then
  AC_MSG_NOTICE(I can't find dot. dot is required for documentation.)
fi

AC_PATH_PROG(pathnescc, nescc)
if test -z "$pathnescc"; then
  AC_MSG_ERROR(I can't find nescc)
fi
nescc_prefix=`(cd $NESCC_PREFIX;pwd)`
AC_SUBST(nescc_prefix)

AC_MSG_CHECKING(for cygwin)
case $host in
  *-*-cygwin*)
    AC_MSG_RESULT(yes)
    JNIPREFIX=
    JNISUFFIX=dll
    JNIVERSIONS="-32. -64."
    INSTALLJNI="install --group=SYSTEM"
    CYGWIN=yes
    ARCH=windows
    ;;
  *-apple-darwin*)
    JNIPREFIX=lib
    JNISUFFIX=jnilib
    JNIVERSIONS=.
    INSTALLJNI="install"
    AC_MSG_RESULT(no)
    DARWIN=yes
    ARCH=darwin
    ;;
  *)
    JNIPREFIX=lib
    JNISUFFIX=so
    JNIVERSIONS="."
    INSTALLJNI="install"
    AC_MSG_RESULT(no)
    ARCH=linux
esac

AM_CONDITIONAL([CYGWIN], [test "$CYGWIN"])
AM_CONDITIONAL([DARWIN], [test "$DARWIN"])
AM_COND_IF([CYGWIN],
      [
       AC_PATH_PROG(GCC32, i686-pc-mingw32-gcc)
       AC_PATH_PROG(GCXX32, i686-pc-mingw32-g++)
#        AC_PATH_PROG(GCC32, i686-w64-mingw32-gcc)
#        AC_PATH_PROG(GCXX32, i686-w64-mingw32-g++)
       AC_PATH_PROG(GCC64, x86_64-w64-mingw32-gcc)
       AC_PATH_PROG(GCXX64, x86_64-w64-mingw32-g++)
       ])

AC_MSG_CHECKING(for JDK location)
JAVAC_DIR=`/bin/sh tinyos/misc/tos-locate-jre --javac`
if test $? -ne 0; then
  AC_ERROR(java not found)
fi
JDK=`dirname "$JAVAC_DIR"`
AC_MSG_RESULT($JDK)

AC_MSG_CHECKING(for location to put JARs)

if test "$prefix" != "NONE"; then
    JAR_DIR="$prefix/lib/java"
else
    JAR_DIR=`/bin/sh tinyos/misc/tos-locate-jre --jni`/../ext
fi

AC_MSG_RESULT($JAR_DIR)

function jnimap {
  for v in $JNIVERSIONS; do
    /bin/echo -n "${JNIPREFIX}$1$v$JNISUFFIX "
  done
}

GETENVLIB=`jnimap getenv`
TOSCOMMLIB=`jnimap toscomm`

AC_SUBST(GETENVLIB)
AC_SUBST(TOSCOMMLIB)
AC_SUBST(JDK)
AC_SUBST(JAR_DIR)
AC_SUBST(INSTALLJNI)
AC_SUBST(JNIPREFIX)
AC_SUBST(JNISUFFIX)

AC_CHECK_LIB(popt, poptGetNextOpt)
AM_CONDITIONAL([POPT_CPPBSL], [test "$ac_cv_lib_popt_poptGetNextOpt" == yes])

AC_CONFIG_HEADERS([config.h])

# Configure BLIP
# Only try to build the BLIP tools on Linux and Mac
AM_COND_IF([CYGWIN], [], [
	AC_CHECK_HEADERS([stdint.h inttypes.h])
	AC_CHECK_HEADERS([netinet/in.h ])
	AC_CHECK_HEADERS([linux/if_tun.h])
	AC_CHECK_HEADERS([arpa/inet.h])
	AC_CHECK_HEADERS([sys/socket.h net/route.h])
        AC_CHECK_HEADERS([net/if.h], [], [],
[#ifdef HAVE_SOCKET_H
#include <sys/socket.h>
#endif
])

	AC_MSG_CHECKING(whether struct in6_addr has u6_addrXX and defines s6_addrXX)
	AC_TRY_COMPILE([#include <netinet/in.h>], [static struct in6_addr in6_u;
	int u =  in6_u.s6_addr16;], [AC_MSG_RESULT(yes); AC_DEFINE([HAVE_IN6_ADDR_S6_ADDR],
	1, [whether struct in6_addr has u6_addrXX and defines s6_addrXX])],
	AC_MSG_RESULT(no))

	AC_MSG_CHECKING(for SIOCADDRT)
	AC_TRY_COMPILE([#include <sys/ioctl.h>], [int x = SIOCADDRT;],
	[AC_MSG_RESULT(yes); AC_DEFINE([HAVE_SIOCADDRT], 1, [weather the SIOCADDRT ioctl is defined])],
	AC_MSG_RESULT(no))

	# sockoption for joining an ipv6 group
	AC_MSG_CHECKING(if IPV6_JOIN_GROUP is defined)
	AC_TRY_COMPILE([#include <netinet/in.h>], [int x = IPV6_JOIN_GROUP;],
	[AC_MSG_RESULT(yes); AC_DEFINE([HAVE_IPV6_JOIN_GROUP], 1,
	                     [weather IPV6_JOIN_GROUP is defined])],
	AC_MSG_RESULT(no))

	AC_MSG_CHECKING(if IPV6_ADD_MEMBERSHIP is defined)
	AC_TRY_COMPILE([#include <netinet/in.h>], [int x = IPV6_ADD_MEMBERSHIP;],
	[AC_MSG_RESULT(yes); AC_DEFINE([HAVE_IPV6_ADD_MEMBERSHIP], 1,
	                     [weather IPV6_ADD_MEMBERSHIP is defined])],
	AC_MSG_RESULT(no))

	# Check where to put the pidfile
	AC_MSG_CHECKING(where to put seqno file)
	AC_ARG_WITH(seqfile,
	[AC_HELP_STRING([--with-seqfile], [Path to the radvd pidfile (/var/run/ip-driver.seq)])],
		PATH_BLIP_SEQFILE=$withval,
		PATH_BLIP_SEQFILE=/var/run/ip-driver.seq)
	AC_MSG_RESULT($PATH_BLIP_SEQFILE)
	AC_SUBST(PATH_BLIP_SEQFILE)

	AC_ARG_ENABLE([lpl],
		[AS_HELP_STRING([--enable-lpl], [assume LPL is in use])],
		AC_DEFINE([BLIP_L2_RETRIES], [1], [Number of link-layer retransmissions])
		[])

	AC_LINK_FILES(tinyos/c/blip/linux/tun_dev_${ARCH}.c, tinyos/c/blip/linux/tun_dev.c)
]);

# Configure coap
AC_CONFIG_SUBDIRS([tinyos/c/coap])

# SF
#AC_CONFIG_HEADERS(tinyos/c/sf/autoconf.h)


AC_OUTPUT(
	Makefile
	platforms/Makefile
	platforms/mica/Makefile
	platforms/mica/cc1000-channelgen/Makefile
	platforms/msp430/Makefile
	platforms/msp430/cppbsl/Makefile
	platforms/msp430/cppbsl/src/Makefile
	platforms/msp430/motelist/motelist-linux
	platforms/msp430/motelist/motelist-macos
	platforms/msp430/motelist/Makefile
	platforms/msp430/pybsl/Makefile
	platforms/msp430/pybsl/tos-bsl.1
	platforms/msp430/pybsl/serial/Makefile
	platforms/msp430/pybsl/serial/serialposix.py
	platforms/msp430/pybsl/serial/__init__.py
	platforms/msp430/pybsl/serial/serialwin32.py
	platforms/msp430/pybsl/elf.py
	platforms/msp430/pybsl/tos-bsl
	platforms/sam3/samba-program.py
	platforms/sam3/Makefile
	platforms/intelmote2/Makefile
	platforms/intelmote2/openocd/Makefile
	platforms/intelmote2/openocd/imote2-ocd-program.py
	platforms/ucmote/Makefile
	platforms/ucmote/mcp2200gpio/Makefile
	platforms/ucmote/motelist2/Makefile
	platforms/ucmote/motelist2/motelist2
	platforms/ucmote/motelist2/tosdevicesearch-cygwin.py
	platforms/ucmote/motelist2/tosdevicesearch-linux.py
	tinyos/Makefile
	tinyos/c/Makefile
	tinyos/c/blip/Makefile
	tinyos/c/blip/lib6lowpan/Makefile
	tinyos/c/blip/lib6lowpan/trace/Makefile
	tinyos/c/coap/Makefile
	tinyos/c/coap/doc/Makefile
	tinyos/c/coap/doc/Doxyfile
	tinyos/c/coap/examples/Makefile
	tinyos/c/serial_tun/Makefile
	tinyos/c/sf/Makefile
	tinyos/cpp/Makefile
	tinyos/cpp/sf/Makefile
	tinyos/java/Makefile
	tinyos/java/net/Makefile
	tinyos/java/net/tinyos/Makefile
	tinyos/java/net/tinyos/comm/Makefile
	tinyos/java/net/tinyos/message/Makefile
	tinyos/java/net/tinyos/mviz/Makefile
	tinyos/java/net/tinyos/packet/Makefile
	tinyos/java/net/tinyos/sf/Makefile
	tinyos/java/net/tinyos/sim/Makefile
	tinyos/java/net/tinyos/tools/Makefile
	tinyos/java/net/tinyos/util/Makefile
	tinyos/jni/Makefile
	tinyos/jni/env/Makefile
	tinyos/jni/serial/Makefile
	tinyos/misc/tos-ident-flags
	tinyos/misc/tos-install-jni
	tinyos/misc/tos-set-symbols
	tinyos/misc/tos-write-buildinfo
	tinyos/misc/tos-write-image
	tinyos/misc/tos-storage-at45db
	tinyos/misc/tos-storage-stm25p
	tinyos/misc/tos-storage-pxa27xp30
	tinyos/misc/tos-dump.py
	tinyos/misc/tos-nwprog
	tinyos/misc/tos-deluge
	tinyos/misc/tos-build-deluge-image
	tinyos/misc/tos-mote-key
	tinyos/misc/tos-check-env
	tinyos/misc/tos-serlook.py
	tinyos/misc/tos-sub-tosdir
	tinyos/misc/Makefile
	tinyos/ncc/Makefile
	tinyos/ncc/mig
	tinyos/ncc/ncg
	tinyos/ncc/nesdoc-archive
	tinyos/ncc/nesdoc-genhtml
	tinyos/ncc/nesdoc-py/Makefile
	tinyos/python/Makefile
	tinyos/python/tos.py
	tinyos/python/message/Makefile
	tinyos/python/misc/Makefile
	tinyos/python/packet/Makefile
	tinyos/python/tossim/Makefile
	tinyos/safe/Makefile
	tinyos/safe/tos-decode-flid
	tinyos/safe/tos-ramsize
)
