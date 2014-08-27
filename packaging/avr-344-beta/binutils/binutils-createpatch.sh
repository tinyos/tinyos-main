#!/bin/bash
#Generally, you don't need to use this. It's just here to show how the atmel-binutils-${version}-autotool.patch was made.
#This script does the pre-configure autoconf/automake stuff on the binutils which is needed for atmel's version, because it's version dependent, and hard to reproduce
#To use it, you must have automake 1.11. Based on atmel's documentation, you should use autoconf 2.64. However, the patch size seems to differs from version to version,
#while the result is the same. Since eighter Atmel or GNU didn't follow they're documentation, there are already files in the tree generated with automake 1.14, autoconf 2.67 and so on
#I tried some setups, and this generated the smallest patch: autoconf 2.69, automake is pointing to automake-1.14, but automake-1.11 is available
#I created the patches on debian squeeze i686 in August 2014. It might not work anymore, but this is here for documentation, not for reusability.
SOURCENAME=binutils
SOURCEVERSION=2.24
ATMELVERSION=3.4.4
ATMELDIRNAME=${SOURCENAME}
ATMELFILENAME=avr-${SOURCENAME}-${SOURCEVERSION}.tar.bz2

MAKE=make
AUTOCONF=autoconf
AUTORECONF=autoreconf

if ! [ -f ${ATMELFILENAME} ]; then
  wget http://distribute.atmel.no/tools/opensource/Atmel-AVR-GNU-Toolchain/${ATMELVERSION}/${ATMELFILENAME}
fi

tar -xjf ${ATMELFILENAME}
cp -R ${ATMELDIRNAME} binutils-ref

pushd ${ATMELDIRNAME}
sed -i 's/  \[m4_fatal(\[Please use exactly Autoconf \]/  \[m4_errprintn(\[Please use exactly Autoconf \]/g' ./config/override.m4
${AUTOCONF}
pushd ld
${AUTORECONF}
popd

BUILDDIR=build
PREFIX=/usr #it doesn't really matter, but we need makefiles for some pre-configuring
mkdir -p ${BUILDDIR}
pushd ${BUILDDIR}
CFLAGS="-Os -g0 -s" ../configure\
                      --prefix=${PREFIX}\
                      --disable-nls\
                      --enable-doc\
                      --target=avr\
                      --libdir=${PREFIX}/lib\
                      --infodir=${PREFIX}/share/info\
                      --mandir=${PREFIX}/share/man\
                      --docdir=${PREFIX}/share/doc/avr-binutils\
                      --disable-werror\
                      --enable-install-libiberty\
                      --enable-instal-libbfd\
                      --enable-maintainer-mode
${MAKE} all-bfd TARGET-bfd=headers
${MAKE} configure-host
${MAKE} all
popd
for DIRECTORY in build autom4te.cache bfd/autom4te.cache binutils/autom4te.cache gas/autom4te.cache ld/autom4te.cache libiberty/autom4te.cache gprof/autom4te.cache opcodes/autom4te.cache
do
  rm -rf ${DIRECTORY}
done
popd

diff -rupdN binutils-ref ${ATMELDIRNAME} > atmel-binutils-${ATMELVERSION}-autotool.patch