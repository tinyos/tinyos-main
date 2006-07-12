# Copyright (c) 2005 Intel Corporation
# All rights reserved.
#
# This file is distributed under the terms in the attached INTEL-LICENSE     
# file. If you do not find these files, copies can be found by writing to
# Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
# 94704.  Attention:  Intel License Inquiry.

# Generate indices for all packages
# Components and interfaces not in a package are ignored.

from re import match
from nesdoc.utils import *
from nesdoc.generators import *
from nesdoc.html import *
from sys import *
from string import *

def generate_indices(compfiles, intffiles):
  # Add filename to the per-package (to) and global (all) lists
  def add_page(filename, to, all):
    fmatch = match("^(.*)\\.(.*)\\.xml$", filename)
    if fmatch:
      package = fmatch.group(1)
      entity = fmatch.group(2)
      packages[package] = True
      if not to.has_key(package):
        to[package] = []
      to[package].append((package, entity))
      all.append((package, entity))
    else:
      fmatch = match("^(.*)\\.xml$", filename)
      if fmatch:
        entity = fmatch.group(1)
        all.append(('', entity))

  # start a list (of interfaces, components or packages)
  def tableforlist_start(ht):
    ht.pushln("table", 'border="0"', 'width="100%"', 'summary=""')
    ht.pushln("tr")
    ht.pushln("td", "nowrap")

  # end a list
  def tableforlist_end(ht):
    ht.popln()
    ht.popln()
    ht.popln()

  # output a list (l) of interfaces or components (kind)
  def entitylist(ht, l, kind):
    tableforlist_start(ht)
    ht.push('div', 'id="heading"')
    ht.p(capitalize(kind))
    ht.pop();
    l.sort(lambda x, y: cmp(x[1].lower(), y[1].lower()))
    ht.push('span', 'id="funcnameshort"')
    for x in l:
      if (x[0] != ''):
        ht.push("a", 'href="../%shtml/%s.%s.html"' % (kind[0], x[0], x[1]),
                'target="bodyFrame"')
      else:
        ht.push("a", 'href="../%shtml/%s.html"' % (kind[0], x[1]),
                'target="bodyFrame"')
      ht.p(x[1])
      ht.pop()
      ht.pln("")
      ht.tagln("br")
    ht.pop()
    ht.tag("p")
    tableforlist_end(ht)

  # Per-package index
  def pkglist(l, pkg, kind):
    if l.has_key(pkg):
      entitylist(pkgfile, l[pkg], kind)

  # collect packages
  allcomponents = []
  allinterfaces = []
  packages = {}
  components = {}
  interfaces = {}
  for x in compfiles: add_page(x, components, allcomponents)
  for x in intffiles: add_page(x, interfaces, allinterfaces)
  packages = packages.keys()
  packages.sort(lambda x, y: cmp(x.lower(), y.lower()))
    
  # Package index
  idxfile = Html("index/packages.html")
  idxfile.title("Package overview")
  idxfile.body()
  tableforlist_start(idxfile)
  idxfile.push("a", 'href="all-.html"', 'target="packageFrame"')
  idxfile.p("Everything")
  idxfile.popln()
  idxfile.tag("p")
  idxfile.pln("Packages")
  for pkg in packages:
    idxfile.tagln("br")
    idxfile.push("a", 'href="%s.html"' % pkg, 'target="packageFrame"')
    idxfile.p(pkg)
    idxfile.pop()
    idxfile.pln("")
  tableforlist_end(idxfile)
  idxfile.close()

  for pkg in packages:
    pkgfile = Html("index/%s.html" % pkg)
    pkgfile.title(pkg)
    pkgfile.body()
    pkgfile.pln(pkg)
    pkgfile.tag("p")
    pkglist(interfaces, pkg, "interfaces")
    pkglist(components, pkg, "components")
    pkgfile.close()

  # Global index
  allfile = Html("index/all-.html")
  allfile.title("All interfaces and components")
  allfile.body()
  entitylist(allfile, allinterfaces, "interfaces")
  entitylist(allfile, allcomponents, "components")
  allfile.close()

  # The actual index, with its three javadoc-style frames
  frame = Html("index.html")
  frame.title("Interfaces and components")
  frame.popln()
  frame.pushln("frameset", 'cols="20%,80%"')
  frame.pushln("frameset", 'rows="30%,70%"')
  frame.tagln("frame", 'src="index/packages.html"', 'name="packageListFrame"',
              'title="Package List"')
  frame.tagln("frame", 'src="index/all-.html"', 'name="packageFrame"',
              'title="All interfaces and components"')
  frame.popln()
  # start on the main application
  frame.tagln("frame", 'src="initial.html"', 'name="bodyFrame"',
              'title="Summary"', 'scrolling="yes"')
  frame.pushln("noframes")
  frame.push("h2")
  frame.p("Warning")
  frame.popln()
  frame.p("nesdoc is designed to be viewed using frames.")
  frame.tag("p")
  frame.p("Click ")
  frame.push("a", 'href="index/packages.html"')
  frame.p("here")
  frame.pop()
  frame.p(" for a minimalistic non-frame interface.")
  frame.popln()
  frame.close()

  # Initial file
  initial = Html("initial.html")
  initial.title("nesdoc introduction")
  initial.body()
  initial.pln("Please select a package from the top-left frame, or an")
  initial.pln("interface or componenent from the bottom-left frame.")
  initial.close()
