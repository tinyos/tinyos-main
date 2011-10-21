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
SRCNAME=msp430-libc
VERSION=20110612
ARCHIVE_FORMAT=tar.bz2
DOWNLOAD_URL=http://sourceforge.net/projects/mspgcc/files/${SRCNAME}/${SRCNAME}-${VERSION}.$(ARCHIVE_FORMAT)
#PATCHDIR=patch
PATCHSTRIP=1
#confiure and compile options
PREFIX=/usr
CONFIGURE_OPTS=$(PREFIX)
#INSTALL_OPTS=

#package options
PKG_NAME=msp430-libc-tinyos
#PKG_VERSION=$(VERSION)
#PKG_RELEASE=$(shell date +%Y%m%d)
#PKG_HOST=$(shell echo $(HOST)|sed 's/.*64/amd64/'|sed 's/.*86/i386/')

#packager options:
#RPMBUILD?=$(shell whereis rpmbuild|sed 's/.*: //'|sed 's/ .*//'|sed 's/.*:.*//g')
#DPKG?=$(shell whereis dpkg-deb|sed 's/.*: //'|sed 's/ .*//'|sed 's/.*:.*//g')

default: check_requirements -userdeb1 -userrpm1

include Generic.mk

Generic.mk:
	cp ../Generic.mk .

ifeq ($(RPMBUILD),)
 RPMTARGET=-dummyrpm
else
 RPMTARGET=-userrpm
endif

ifeq ($(DPKG),)
 DEBTARGET=-dummydeb
else
 DEBTARGET=-userdeb
endif

usercompile: patch
	cd $(SRC_DIRECTORY)/src&&make PREFIX=$(PREFIX)

userinstall: usercompile
	install -d $(ABS_PKG_DIR)
	cd $(SRC_DIRECTORY)/src&&make PREFIX=$(ABS_PKG_DIR)/$(PREFIX) install

-userdeb1: $(DEBTARGET)
-userrpm1: $(RPMTARGET)

-userdeb: userinstall $(PKG_DIR).deb
-userrpm: userinstall make_pkg_rpmdone

-check_spec_requirements:

-cleanup:

