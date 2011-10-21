# Copyright (c) 2011, University of Szeged
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 
# - Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
# - Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following
# disclaimer in the documentation and/or other materials provided
# with the distribution.
# - Neither the name of University of Szeged nor the names of its
# ontributors may be used to endorse or promote products derived
# from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
# OF THE POSSIBILITY OF SUCH DAMAGE.
# 
# Author:Andras Biro <bbandi86@gmail.com>

#download and patch options
SRCNAME=gcc
VERSION=4.5.3
ARCHIVE_FORMAT=tar.bz2

MPFR_VER=2.4.2
MPFR=mpfr-${MPFR_VER}
GMP_VER=4.3.2
GMP=gmp-${GMP_VER}
MPC_VER=0.8.1
MPC=mpc-${MPC_VER}

DOWNLOAD_URL=ftp://ftp.gnu.org/gnu/$(SRCNAME)/$(SRCNAME)-$(VERSION)/$(SRCNAME)-$(VERSION).tar.bz2\
http://www.mpfr.org/${MPFR}/${MPFR}.tar.gz\
http://ftp.gnu.org/gnu/gmp/${GMP}.tar.gz\
http://www.multiprecision.org/mpc/download/${MPC}.tar.gz
UNPACK_TARGET=-user_unpack
PATCHSTRIP=1

#confiure and compile options
AS=/usr/bin/msp430-as
LD=/usr/bin/msp430-ld
PREFIX=/usr
CONFIGURE_OPTS=--prefix=$(PREFIX) --disable-libssp --enable-languages=c,c++ --infodir=$(PREFIX)/share/info --libdir=$(PREFIX)/lib --libexecdir=$(PREFIX)/lib --mandir=$(PREFIX)/share/man --target=msp430 --with-ld=$(LD) --with-as=$(AS)
BUILD_SUBDIR=build

#package options
PKG_NAME=msp430-gcc-tinyos
#PKG_VERSION=$(VERSION)
#PKG_RELEASE=$(shell date +%Y%m%d)
#PKG_HOST=$(shell echo $(HOST)|sed 's/.*64/amd64/'|sed 's/.*86/i386/')

#packager options:
#RPMBUILD?=$(shell whereis rpmbuild|sed 's/.*: //'|sed 's/ .*//'|sed 's/.*:.*//g')
#DPKG?=$(shell whereis dpkg-deb|sed 's/.*: //'|sed 's/ .*//'|sed 's/.*:.*//g')

include Generic.mk

Generic.mk:
	cp ../Generic.mk .

-user_unpack: get $(SRCNAME)-$(VERSION)

$(SRCNAME)-$(VERSION):
	tar -xjf $(SRCNAME)-$(VERSION).tar.bz2
	tar -C $(SRCNAME)-$(VERSION) -xzf ${MPFR}.tar.gz
	tar -C $(SRCNAME)-$(VERSION) -xzf ${GMP}.tar.gz
	tar -C $(SRCNAME)-$(VERSION) -xzf ${MPC}.tar.gz
	cd $(SRCNAME)-$(VERSION)&&mv ${MPFR} mpfr
	cd $(SRCNAME)-$(VERSION)&&mv ${GMP} gmp
	cd $(SRCNAME)-$(VERSION)&&mv ${MPC} mpc

-check_spec_requirements:

-cleanup:
	rm -rf $(PKG_DIR)/usr/lib/libiberty.a \
		$(PKG_DIR)/usr/share/man/man7 \
		$(PKG_DIR)/usr/share/info	


