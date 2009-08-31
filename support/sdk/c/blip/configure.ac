AC_INIT([blip], [2.1], [stevedh@eecs.berkeley.edu])
AM_INIT_AUTOMAKE([-Wall -Werror foreign])
AC_PROG_RANLIB
AC_PROG_CC
AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_HEADERS([config.h])
AC_CONFIG_FILES([
 Makefile
 lib6lowpan/Makefile
 driver/Makefile
])

AC_ARG_ENABLE([lpl],
        [AS_HELP_STRING([--enable-lpl], [assume LPL is in use])],
        AC_DEFINE([BLIP_L2_RETRIES], [1], [Number of link-layer retransmissions])
        [])


AC_CONFIG_SUBDIRS([driver/radvd-1.0])
AC_OUTPUT
