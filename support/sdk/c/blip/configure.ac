AC_INIT([blip], [2.1], [stevedh@eecs.berkeley.edu])
AC_CANONICAL_SYSTEM
echo $ac_n "building for architecture""... $ac_c" 1>&6
case "$target" in
        *linux*)
                AC_MSG_RESULT(linux)
                arch=linux
        ;;
        *darwin*)
                AC_MSG_RESULT(darwin)
                arch=darwin

                dnl exit if tun isn't installed
                AC_MSG_CHECKING(for tun device)
                if test -c /dev/tun0; then
                AC_MSG_RESULT(yes)
                else
                AC_MSG_ERROR([ERROR: /dev/tun0 not found.  You probably need 
to install the tuntap kernel extension from http://tuntaposx.sourceforge.net/])
                fi

        ;;
        *)      
                AC_MSG_RESULT(unknown)
                AC_MSG_ERROR([currently only Linux and OSX are supported])
        ;;
esac
dnl AC_DEFINE([PLATFORM], [${arch}])

dnl check programs
AM_INIT_AUTOMAKE([-Wall -Werror foreign])
AC_PROG_RANLIB
AC_PROG_CC
AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_HEADERS([config.h])
AC_CONFIG_FILES([
 Makefile
 lib6lowpan/Makefile
 lib6lowpan/trace/Makefile
])
dnl  driver/Makefile

dnl check various platform include files
AC_CHECK_HEADERS([stdint.h inttypes.h])
AC_CHECK_HEADERS([netinet/in.h ])
AC_CHECK_HEADERS([linux/if_tun.h])
AC_CHECK_HEADERS([arpa/inet.h])
AC_CHECK_HEADERS([sys/socket.h net/route.h net/if.h], [], [], 
[[#if HAVE_SYS_SOCKET_H
#include <sys/socket.h>
#endif

#if HAVE_NET_ROUTE_H
#include <net/route.h>
#endif]])

AC_MSG_CHECKING(whether struct in6_addr has u6_addrXX and defines s6_addrXX)
AC_TRY_COMPILE([#include <netinet/in.h>], [static struct in6_addr in6_u; 
int u =  in6_u.s6_addr16;], [AC_MSG_RESULT(yes); AC_DEFINE([HAVE_IN6_ADDR_S6_ADDR],
1, [whether struct in6_addr has u6_addrXX and defines s6_addrXX])],
AC_MSG_RESULT(no))

AC_MSG_CHECKING(for SIOCADDRT)
AC_TRY_COMPILE([#include <sys/ioctl.h>], [int x = SIOCADDRT;],
[AC_MSG_RESULT(yes); AC_DEFINE([HAVE_SIOCADDRT], 1, [weather the SIOCADDRT ioctl is defined])],
AC_MSG_RESULT(no))

dnl sockoption for joining an ipv6 group
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

dnl if htons requires -lc
dnl AC_MSG_CHECKING(if htons requires -lc)
dnl AC_TRY_COMPILE([#include <arpa/inet.h>], [int x = htons(10);],
dnl [AC_MSG_RESULT(no)],
dnl [AC_MSG_RESULT(yes); LDFLAGS+=-lc])

dnl Check where to put the pidfile
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

AC_LINK_FILES(linux/tun_dev_${arch}.c, linux/tun_dev.c)
dnl AC_LINK_FILES(driver/routing-${arch}.c, driver/routing-platform.c)
dnl AC_LINK_FILES(driver/netlink-${arch}.c, driver/netlink.c)
dnl AC_CONFIG_SUBDIRS([driver/radvd-1.0])
AC_OUTPUT
