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
SRCNAME=binutils
VERSION=2.17
ARCHIVE_FORMAT=tar.bz2
DOWNLOAD_URL=http://ftp.gnu.org/gnu/$(SRCNAME)/$(SRCNAME)-$(VERSION).$(ARCHIVE_FORMAT)
#PATCHDIR=patch

#confiure and compile options
PREFIX=/usr
CONFIGURE_OPTS=--prefix=$(PREFIX) --disable-nls --infodir=$(PREFIX)/share/info --libdir=$(PREFIX)/lib --mandir=$(PREFIX)/share/man --disable-werror --target=avr
INSTALL_OPTS=tooldir=/usr install

#package options
PKG_NAME=avr-binutils-tinyos
#PKG_VERSION=$(VERSION)
#PKG_RELEASE=$(shell date +%Y%m%d)
#PKG_HOST=$(shell echo $(HOST)|sed 's/.*64/amd64/'|sed 's/.*86/i386/')

#packager options:
#RPMBUILD?=$(shell whereis rpmbuild|sed 's/.*: //'|sed 's/ .*//'|sed 's/.*:.*//g')
#DPKG?=$(shell whereis dpkg-deb|sed 's/.*: //'|sed 's/ .*//'|sed 's/.*:.*//g')

include Generic.mk

Generic.mk:
	cp ../Generic.mk .

-check_spec_requirements:
	which makeinfo

-cleanup:
	rm -f $(PKG_DIR)/usr/lib/libiberty.a \
		$(PKG_DIR)/usr/share/info/dir \
		$(PKG_DIR)/usr/bin/addr2line* \
		$(PKG_DIR)/usr/bin/ar* \
		$(PKG_DIR)/usr/bin/as* \
		$(PKG_DIR)/usr/bin/c++filt* \
		$(PKG_DIR)/usr/bin/gprof* \
		$(PKG_DIR)/usr/bin/ld* \
		$(PKG_DIR)/usr/bin/nm* \
		$(PKG_DIR)/usr/bin/objcopy* \
		$(PKG_DIR)/usr/bin/objdump* \
		$(PKG_DIR)/usr/bin/ranlib* \
		$(PKG_DIR)/usr/bin/readelf* \
		$(PKG_DIR)/usr/bin/size* \
		$(PKG_DIR)/usr/bin/strings* \
		$(PKG_DIR)/usr/bin/strip*
	#rename info files to avr-*
	-mv $(PKG_DIR)/usr/share/info/in.info $(PKG_DIR)/usr/share/info/avr-in.info
	-mv $(PKG_DIR)/usr/share/info/as.info $(PKG_DIR)/usr/share/info/avr-as.info
	-mv $(PKG_DIR)/usr/share/info/bfd.info $(PKG_DIR)/usr/share/info/avr-bfd.info
	-mv $(PKG_DIR)/usr/share/info/binutils.info $(PKG_DIR)/usr/share/info/avr-binutils.info
	-mv $(PKG_DIR)/usr/share/info/configure.info $(PKG_DIR)/usr/share/info/avr-configure.info
	-mv $(PKG_DIR)/usr/share/info/ld.info $(PKG_DIR)/usr/share/info/avr-ld.info
	-mv $(PKG_DIR)/usr/share/info/standards.info $(PKG_DIR)/usr/share/info/avr-standards.info