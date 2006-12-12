#
# $Id: Makefile.am,v 1.4 2006-12-12 18:23:00 vlahan Exp $
#
# uisp - The Micro In-System Programmer for Atmel AVR microcontrollers.
# Copyright (C) 2002  Theodore A. Roth
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# Makefile.am -- Process this file with automake to produce Makefile.in
#

auxdir               = @ac_aux_dir@
AUX_DIST             = $(auxdir)/install-sh $(auxdir)/missing \
                       $(auxdir)/mkinstalldirs $(auxdir)/README

man_MANS             = uisp.1

AUX_DIST_EXTRA       = 
EXTRA_DIST           = bootstrap config acconfig.h \
                       CHANGES CHANGES.old \
                       kernel/patch-2.2.17-ppdev1.gz \
                       pavr/Makefile pavr/pavr.c \
                       doc/HOWTO.windows doc/README.stk500 \
                       doc/README.xilinx \
                       doc/uisp-parport-connect.txt \
                       uisp.1.in 

AUTOMAKE_OPTIONS     = foreign

if CYGWIN
SUBDIRS              = src kernel
else
SUBDIRS              = src
endif
DIST_SUBDIRS         = $(SUBDIRS)

MAINTAINERCLEANFILES = Makefile.in aclocal.m4 configure src/config-h.in \
                       src/stamp-h.in $(AUX_DIST)

ACLOCAL              = aclocal -I $(auxdir)

install_aux_files    = AUTHORS ChangeLog COPYING INSTALL CHANGES CHANGES.old \
                       TODO

DOC_INST_DIR         = $(DESTDIR)$(datadir)/doc/uisp-$(VERSION)

install-data-local:
	$(mkinstalldirs) $(DOC_INST_DIR)
	for file in $(install_aux_files) ; do \
	  echo " $(INSTALL_DATA) $$file $(DOC_INST_DIR)/$$file"; \
	  $(INSTALL_DATA) $(srcdir)/$$file $(DOC_INST_DIR)/$$file; \
	done

uninstall-local:
	rm -rf $(DOC_INST_DIR)

dist-hook: uisp.spec
	cp uisp.spec $(distdir)/uisp.spec
	rm -rf $(distdir)/config/CVS
