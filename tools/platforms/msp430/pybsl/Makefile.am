AUTOMAKE_OPTIONS = foreign

sharedocdir=$(datadir)/doc/tinyos-tools-@PACKAGE_VERSION@

sharedoc_DATA = tos-bsl.txt tos-bsl-license.txt

dist_man_MANS = tos-bsl.1

if CYGWIN
# Cygwin support using native windows binary
# (this code is not compatible with cygwin's python)

install: tos-bsl-win.tar.gz
	tar xzvf tos-bsl-win.tar.gz -C $(DESTDIR)$(bindir)

else
# Linux support
SUBDIRS = serial

bin_SCRIPTS = tos-bsl

# Install the elf.py
elfpy_PYTHON = elf.py
elfpydir = $(pythondir)/tinyos

endif
