Introduction
============

The TinyOS Extension Proposals (TEPs) are written using the
reStructuredText. Converting them into HTML documents can be performed
using the "rst2html" tool from the python Docutils package::

    http://docutils.sourceforge.net

Installing Docutils using a native package
==========================================

Many Linux distributions provide a native Docutils package. We provide
short instructions for installing the package on Fedora Core 3, Fedora
Core 4 and Debian.

Fedora Core 3
-------------

The Docutils package is part of the "extras" distribution channel. 

When using the "yum" package manager, the "extras" repository can be
added by creating a new extras.repo file in the /etc/yum/yum.repos.d
directory with the content::

    [extras]
    name=Fedora Extras - $releasever - $basearch
    baseurl=http://download.fedora.redhat.com/pub/fedora/linux/extras/$releasever/$basearch/
    gpgcheck=1
    enabled=1

After that, Docutils can be installed by issuing::

   sudo yum install python-docutils

Alternatively, the Docutils RPM package can be downloaded manually
from::

    http://download.fedora.redhat.com/pub/fedora/linux/extras/3/i386/python-docutils-0.3.9-1.fc3.noarch.rpm 

and installed using:

    sudo rpm -ivh python-docutils-0.3.9-1.fc3.noarch.rpm 


Fedora Core 4
-------------

In Fedora Core 4, the "extras" repository is already configured, but
disabled by default. The docutils package can be installed using::

    sudo yum --enablerepo=extras install python-docutils

Alternatively, the Docutils RPM package can be downloaded manually
from::

    http://download.fedora.redhat.com/pub/fedora/linux/extras/4/i386/python-docutils-0.3.9-1.fc4.noarch.rpm

and installed using:

    sudo rpm -ivh python-docutils-0.3.9-1.fc4.noarch.rpm 


Debian
------

The Docutils are packaged in the python-docutils DEB package and can
be installed using:

    sudo apt-get install python-docutils

Alternatively, the Docutils DEB package can be download (for Debian
stable) from::

    http://packages.debian.org/cgi-bin/download.pl?arch=all&file=pool%2Fmain%2Fp%2Fpython-docutils%2Fpython-docutils_0.3.7-2_all.deb&md5sum=4f21cac36c65f9edc080bc5b77169c51&arch=all&type=main

and installed using::

    sudo dpkg -i  python-docutils_0.3.7-2_all.deb


Installing Docutils from sources
================================

The latest Docutils source release (0.3.9) can be downloaded from::

http://prdownloads.sourceforge.net/docutils/docutils-0.3.9.tar.gz?download

The source is packaged using python Distutils and can be installed using:: 

    sudo python setup.py install

