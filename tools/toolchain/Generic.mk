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

##
#This is the "engine" of the engine of the package building system, y
#
##
PKG_NAME?=$(SRC_NAME)
PKG_VERSION ?= $(VERSION)
PKG_RELEASE ?= $(shell date +%Y%m%d)
SRC_DIRECTORY?=$(SRCNAME)-$(VERSION)
SRC_ARCHIVE?=$(SRCNAME)-$(VERSION)
HOST ?= $(shell uname -m)
PKG_HOST ?= $(shell echo $(HOST)|sed 's/.*64/amd64/'|sed 's/.*86/i386/')
PKG_DIR = $(PKG_NAME)_$(PKG_VERSION)-$(PKG_RELEASE)_$(PKG_HOST)
ABS_PKG_DIR=$(shell echo $(PWD)/$(PKG_DIR)|sed 's/\//\\\//g')
PATCHDIR?=patch
PATCHSTRIP?=0
#check package builders: these variables are the absolute path to the packager, or empty if the packager is not present
RPMBUILD?=$(shell whereis rpmbuild|sed 's/.*: //'|sed 's/ .*//'|sed 's/.*:.*//g')
DPKG?=$(shell whereis dpkg-deb|sed 's/.*: //'|sed 's/ .*//'|sed 's/.*:.*//g')
UNPACK_TARGET?=$(SRC_DIRECTORY)/configure
CONFIG_LINE?=./configure $(CONFIGURE_OPTS)
ifneq ($(BUILD_SUBDIR),)
  REAL_CONFIG_LINE=install -d $(BUILD_SUBDIR)&&cd $(BUILD_SUBDIR)&&.$(CONFIG_LINE)
else
  REAL_CONFIG_LINE=$(CONFIG_LINE)
endif

ifeq ($(RPMBUILD),)
 RPMTARGET=-dummyrpm
else
 RPMTARGET=-realrpm
endif

ifeq ($(DPKG),)
 DEBTARGET=-dummydeb
else
 DEBTARGET=-realdeb
endif

#set up the decompress command
ifeq ($(ARCHIVE_FORMAT),tar.Z)
  DECOMPRESS_CMD?=tar -xZf
  CHECK_DECOMP=uncompress
endif
ifeq ($(ARCHIVE_FORMAT),tar.gz)
  DECOMPRESS_CMD?=tar -xzf
  CHECK_DECOMP=gunzip
endif
ifeq ($(ARCHIVE_FORMAT),tar.bz2)
  DECOMPRESS_CMD?=tar -xjf
  CHECK_DECOMP=bunzip2
endif
ifeq ($(ARCHIVE_FORMAT),tar.xz)
  DECOMPRESS_CMD?=tar -xJf
  CHECK_DECOMP=unxz
endif
ifeq ($(DECOMPRESS_CMD),)
  $(error Unknown archive format: $(ARCHIVE_FORMAT))
endif
CHECK_DECOMP?=tar #if someone set the decompress_cmd, but not the check_decomp

#check if there's any patch
PATCHNUM=$(shell ls -1 $(PATCHDIR)/*.patch|wc -l)
ifeq ($(PATCHNUM),0)
 PATCHTARGET=-dummypatch
else
 PATCHTARGET=-realpatch
endif

ifneq ($(BOOTSTRAP_CMD),)
	REALBOOTSTRAP_CMD=cd $(SRC_DIRECTORY)&&./$(BOOTSTRAP_CMD)
endif

all: check_requirements $(DEBTARGET) $(RPMTARGET)

check_requirements: -check_spec_requirements -check_generic_requirements
-check_generic_requirements: -check_spec_requirements
	which wget
	which whereis
	which sed
	which tar
	which $(CHECK_DECOMP)

help:
	@echo "default target: all"
	@echo ""
	@echo "all: creates rpm (if rpmbuild is available) and deb (if dpkg-deb is available) packages"
	@echo ""
	@echo "check_requirements: check build requirements"
	@echo "get: downloads the source from $(DOWNLOAD_URL)"
	@echo "unpack: uncopresses the source"
	@echo "patch: applying all patches from directory $(PATCHDIR)"
	@echo ""
	@echo "configure: configure package with options: $(CONFIGURE_OPTS)"
	@echo "compile: compiles package"
	@echo "pacakge: install the package to $(PKG_DIR)"
	@echo
	@echo "deb: creates deb package from $(PKG_DIR) if dpkg-deb is available"
	@echo "rpm: creates rpm package from $(PKG_DIR) if rpmbuild is available"
	@echo
	@echo "cleanpackage: removes generated packages, install directory, and edited spec/control file"
	@echo "cleanbuild: removes everything, except downloaded archive"
	@echo "clean: removes everything"
	rm -f Generic.mk

-dummyrpm:
	@echo "Can't found rpmbuild. Rpm package will not be created"

-dummydeb:
	@echo "Can't found dpkg. Deb package will not be created"

rpm: $(RPMTARGET)
deb: $(DEBTARGET)

get: $(SRC_ARCHIVE).$(ARCHIVE_FORMAT)
$(SRC_ARCHIVE).$(ARCHIVE_FORMAT):
	wget $(DOWNLOAD_URL)	

unpack: get $(UNPACK_TARGET)
$(SRC_DIRECTORY)/configure:
	$(DECOMPRESS_CMD) $(SRC_ARCHIVE).$(ARCHIVE_FORMAT)

patch: $(PATCHTARGET)
-dummypatch: unpack
-realpatch: unpack make_patchdone
make_patchdone:
	cd $(SRC_DIRECTORY)&&cat ../$(PATCHDIR)/*.patch|patch -p$(PATCHSTRIP) && cd .. && touch make_patchdone #just for the makefile

configure: patch $(SRC_DIRECTORY)/$(BUILD_SUBDIR)/Makefile
$(SRC_DIRECTORY)/$(BUILD_SUBDIR)/Makefile:
	$(REALBOOTSTRAP_CMD)
	cd $(SRC_DIRECTORY)&&$(REAL_CONFIG_LINE)

compile: configure make_compiledone
make_compiledone:
	cd $(SRC_DIRECTORY)/$(BUILD_SUBDIR)&&make&&cd ..&&touch make_compiledone #just for the makefile

-realdeb: package $(PKG_DIR).deb
$(PKG_DIR).deb:
	which fakeroot
	install -d $(PKG_DIR)/DEBIAN
	if [ -f debpostinst ]; then cp debpostinst $(PKG_DIR)/DEBIAN/postinst&&chmod 755 $(PKG_DIR)/DEBIAN/postinst; fi
	if [ -f debprerm ]; then cp debpostinst $(PKG_DIR)/DEBIAN/prerm&&chmod 755 $(PKG_DIR)/DEBIAN/prerm; fi
	sed 's/PKG_VERSION/$(PKG_VERSION)-$(PKG_RELEASE)/g' debcontrol | \
		sed 's/PKG_ARCHITECTURE/$(PKG_HOST)/g' > $(PKG_DIR)/DEBIAN/control&& \
		fakeroot $(DPKG) --build $(PKG_DIR)&& \
		rm -rf $(PKG_DIR)/DEBIAN

-realrpm: package make_pkg_rpmdone
make_pkg_rpmdone:
	sed 's/PKG_VERSION/$(PKG_VERSION)/g' rpm.spec | \
		sed 's/PKG_RELEASE/$(PKG_RELEASE)/g'> realrpm.spec && \
		$(RPMBUILD) --target=$(HOST) --buildroot=$(ABS_PKG_DIR) -bb realrpm.spec&&rm realrpm.spec&&touch make_pkg_rpmdone&&rm -f make_pkg_packagedone

cleanpackage:
	rm -rf $(PKG_DIR)
	rm -f *.rpm *.deb
	rm -f realrpm.spec
	rm -f make_pkg_*
	rm -f Generic.mk

cleanbuild: cleanpackage
	rm -rf $(SRC_DIRECTORY)
	rm -f make_*

clean: cleanbuild
	rm -f $(SRC_ARCHIVE).$(ARCHIVE_FORMAT)

package: compile -install -cleanup make_pkg_packagedone

-install:
	install -d $(PKG_DIR)
	cd $(SRC_DIRECTORY)/$(BUILD_SUBDIR)&&make DESTDIR=$(ABS_PKG_DIR) $(INSTALL_OPTS) install

make_pkg_packagedone:
	touch make_pkg_packagedone

.PHONY : all -check_generic_requirements check_requirements -check_spec_requirements help -dummydeb -dummyrpm deb rpm -realrpm -realdeb get unpack patch -dummypatch  -realpatch configure compile clean cleanbuild cleanpackage -cleanup -install