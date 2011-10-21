SRCNAME=binutils
VERSION=2.21.1
SRC_ARCHIVE=${SRCNAME}-${VERSION}a
ARCHIVE_FORMAT=tar.bz2
DOWNLOAD_URL=http://ftp.gnu.org/gnu/binutils/${SRC_ARCHIVE}.${ARCHIVE_FORMAT}

PATCHSTRIP=1

PREFIX=/usr
CONFIGURE_OPTS=--prefix=$(PREFIX) --target=msp430 --infodir=$(PREFIX)/share/info --libdir=$(PREFIX)/lib --mandir=$(PREFIX)/share/man


PKG_NAME=msp430-binutils-tinyos

include Generic.mk

Generic.mk:
	cp ../Generic.mk .

-check_spec_requirements:

-cleanup:
	rm -rf $(PKG_DIR)/usr/lib/
	rm -rf $(PKG_DIR)/usr/share/locale
	rm -f $(PKG_DIR)/usr/share/info/dir
	#rename info files to msp430-*
	-mv $(PKG_DIR)/usr/share/info/in.info $(PKG_DIR)/usr/share/info/msp430-in.info
	-mv $(PKG_DIR)/usr/share/info/as.info $(PKG_DIR)/usr/share/info/msp430-as.info
	-mv $(PKG_DIR)/usr/share/info/bfd.info $(PKG_DIR)/usr/share/info/msp430-bfd.info
	-mv $(PKG_DIR)/usr/share/info/binutils.info $(PKG_DIR)/usr/share/info/msp430-binutils.info
	-mv $(PKG_DIR)/usr/share/info/configure.info $(PKG_DIR)/usr/share/info/msp430-configure.info
	-mv $(PKG_DIR)/usr/share/info/ld.info $(PKG_DIR)/usr/share/info/msp430-ld.info
	-mv $(PKG_DIR)/usr/share/info/standards.info $(PKG_DIR)/usr/share/info/msp430-standards.info
	-mv $(PKG_DIR)/usr/share/info/gprof.info $(PKG_DIR)/usr/share/info/msp430-gprof.info