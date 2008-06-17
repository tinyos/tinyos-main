# -*- python -*-
# Copyright (c) 2005 Intel Corporation
# All rights reserved.
#
# This file is distributed under the terms in the attached INTEL-LICENSE     
# file. If you do not find these files, copies can be found by writing to
# Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
# 94704.  Attention:  Intel License Inquiry.

# Archive nesdoc information from a given compilation in a nesdoc repository.
#
# A nesdoc repository is a directory containing separate XML files for each
# known interface and component (in the "interfaces" and "components"
# subdirectories respectively). These files have basically the same format
# as a single interfacedef and component element from the nesC XML dump
# format, with the following changes:
#  - all "interfacedef", "interfacedef-ref", "component" and "component-ref"
#    elements have an extra "nicename" attribute which stores the full
#    `package name' for the corresponding element (see below for details)
#  - components have two extra sub-elements:
#    o "specification": a list of the "interface" and "function"
#       elements that form the components specification
#    o "referenced": the "interface" and "function" elements referenced
#      from the wiring graph
#      the "component" elements referenced from these "interface" and
#      "function" elements
#      (but the "referenced" list excludes self-references, i.e., the
#      component itself and the "interface" and "function" elements
#      already found in "specification")

# A `package name' is a component or interface name prefixed with its path
# relative to a set of "top directories", and with path separators replaced
# by dots. The root of a TinyOS installation is usually the single top
# directory, but more can be specified with the -topdir option.


from xml.dom import *
from xml.dom.minidom import *
from sys import *
from getopt import getopt
from string import *
from nesdoc.utils import *
from nesdoc.graph import generate_graph
from nesdoc.html import *
import os

def check(x):
  if not x:
    print "%s is not a nesC documentation file" % argv[1]
    exit(2)
  return x

def get1(x, tag):
  return check(xml_tagfind(x, tag))

def usage():
  print "Usage: %s [-t dir] [--topdir dir] [--preserve] [--app] [--quiet] repository" % argv[0]
  print "  where -t/--topdir specify prefixes to remove from file names"
  print "  to create nice, package-like names for interface and components"
  print "  (based on their full filename)."
  print "  If --preserve is specified, existing XML files are preserved."
  print "  If --app is specified, a page for this application is created in the"
  print "  current directory."
  print "  If --quiet is specified, the program is less verbose."
  print "  The XML input is read from stdin."

# Return package name for elem, or None if no valid name is found
# (i.e., if the element's file name does not match any known topdir)
def packagename(elem):
  loc = elem.getAttribute("loc")
  colon = index(loc, ":")
  filename = canonicalise(loc[colon + 1:])
  for dir in topdirs:
    dirlen = len(dir)
    if filename[0:dirlen] == dir:
      filename = filename[dirlen:]
      break
  if filename[0] == "/":
    return None
  else:
    return replace(replace(filename, ".nc", ""), "/", ".")

# simplify file names (for generating package names, so no need to
# preserve path validity):
#  empty strings become ./
#  windows paths are made unix-like:
#    c: becomes /c/
#    all \ become /
def canonicalise(name):
  if name == "":
    name = "."
  if (name[1:2] == ":"): # windows disk names
    name = "/%s/%s" %(name[0], name[2:])
  name = replace(name, "\\", "/")
  return name
  
# canonicalise a directory. like canonicalise, but ensures
# there is trailing /
def canonicalisedir(dirname):
  dirname = canonicalise(dirname)
  if dirname[-1] != "/":
    return dirname + "/"
  else:
    return dirname

# option processing. See usage string for details.
(opts, args) = getopt(argv[1:], "t:", [ "topdir=", "preserve", "app", "quiet" ])
topopts = filter(lambda (x): x[0] != "--preserve" and x[0] != "--app" and x[0] != "--quiet", opts)
preserve = filter(lambda(x): x[0] == "--preserve", opts) != []
app = filter(lambda(x): x[0] == "--app", opts) != []
quiet = filter(lambda(x): x[0] == "--quiet", opts) != []
topdirs = map(lambda (x): canonicalisedir(x[1]), topopts)
if len(args) != 1:
  usage()

repository = args[0]
try:
  dom = parse(stdin)
except xml.parsers.expat.ExpatError:
  nfail("nesdoc failed: no valid input")
creator = xml.dom.minidom.getDOMImplementation()
check(dom.documentElement.tagName == "nesc")

interfacedefs = get1(dom, "interfacedefs")
components = get1(dom, "components")
interfaces = get1(dom, "interfaces")
functions = get1(dom, "functions")

# index everything
refidx = {}
qnameidx = {}
for x in interfaces.getElementsByTagName("interface"):
  refidx[x.getAttribute("ref")] = x
for x in functions.getElementsByTagName("function"):
  refidx[x.getAttribute("ref")] = x
for x in components.getElementsByTagName("component"):
  qnameidx[x.getAttribute("qname")] = x
for x in interfacedefs.getElementsByTagName("interfacedef"):
  qnameidx[x.getAttribute("qname")] = x

# collect specification elements by component
speclist = {}
# interfaces
for x in interfaces.getElementsByTagName("interface"):
  incomponent = get1(x, "component-ref").getAttribute("qname")
  if speclist.has_key(incomponent):
    speclist[incomponent].append(x)
  else:
    speclist[incomponent] = [x]
# and bare commands, events
for x in functions.getElementsByTagName("function"):
  # hack: tasks don't show up with a command/event attribute
  # don't include commands/events from interfaces
  if (x.hasAttribute("event") or x.hasAttribute("command")) and (not xml_tag(x, "interface-ref")):
    incomponent = get1(x, "component-ref").getAttribute("qname")
    if speclist.has_key(incomponent):
      speclist[incomponent].append(x)
    else:
      speclist[incomponent] = [x]

# add nicename (i.e., with package prefix) attributes to all interfacedef,
# interfacedef-ref, component and component-ref elements
nicenames = {}
def define_nicename(x):
  name = x.getAttribute("qname")
  nicename = packagename(x)
  if nicename == None:
    nicename = name
  nicenames[name] = nicename
def set_nicename(x):
  x.setAttribute("nicename", nicenames[x.getAttribute("qname")])
for x in interfacedefs.getElementsByTagName("interfacedef"):
  define_nicename(x)
  set_nicename(x)
for x in components.getElementsByTagName("component"):
  define_nicename(x)
  set_nicename(x)
for x in dom.getElementsByTagName("interfacedef-ref"):
  set_nicename(x)
for x in dom.getElementsByTagName("component-ref"):
  set_nicename(x)

# Do the app stuff if requested
if app:
  # The firt component is the main application component.
  toplevel = xml_idx(components, 0)
  name = toplevel.getAttribute("qname")
  nicename = toplevel.getAttribute("nicename")
  wiring = xml_tag(xml_tag(dom, "nesc"), "wiring")
  generate_graph(".", repository, dom, wiring, name, nicename)

  ht = Html("%s.html" % nicename)
  ht.title("Application: " + nicename)
  ht.body()
  ht.push("h2");
  ht.p("Application: " + nicename)
  ht.popln();
  ht.pushln("map", 'name="comp"')
  cmap = file("%s.cmap" % nicename)
  for line in cmap.readlines():
    ht.pln(line)
  cmap.close()
  ht.popln()
  ht.tag("img", 'src="%s.png"' % nicename, 'usemap="#comp"', 'id=imgwiring')
  ht.close()

# save xml information per-interface and per-component in the specified
# repository
nmkdir(repository)
chdir(repository)
nmkdir("interfaces")
nmkdir("components")

# save interface definitions
for x in interfacedefs.getElementsByTagName("interfacedef"):
  name = x.getAttribute("qname")
  nicename = x.getAttribute("nicename")
  filename = "interfaces/%s.xml" % nicename
  if preserve and os.path.exists(filename):
    continue
  if not quiet:
    print "interface %s (%s)" % (name, nicename)
  doc = creator.createDocument(None, None, None)
  copy = x.cloneNode(True)
  doc.appendChild(copy)
  ifile = file(filename, "w")
  doc.writexml(ifile)
  doc.unlink()
  ifile.close()

# save component definitions, excluding instantiations
for x in components.getElementsByTagName("component"):
  if len(x.getElementsByTagName("instance")) == 0:
    # not an instance
    name = x.getAttribute("qname")
    nicename = x.getAttribute("nicename")
    filename = "components/%s.xml" % nicename
    if preserve and os.path.exists(filename):
      continue
    if not quiet:
      print "component %s (%s)" % (name, nicename)
    doc = creator.createDocument(None, None, None)
    # copy component and create its specification
    copy = x.cloneNode(True)
    spec = dom.createElement("specification")
    copy.appendChild(spec)
    try:
      for intf in speclist[name]:
        spec.appendChild(intf.cloneNode(True))
    except KeyError:
      0

    # collect information used in wiring graph
    allelems = {}
    allcomps = {}
    def addelem(wireref):
      actualref = xml_tagset(wireref, ["interface-ref", "function-ref"])
      elemref = actualref.getAttribute("ref")
      elem = refidx[elemref]
      compname = xml_tag(elem, "component-ref").getAttribute("qname")
      # exclude self-references, those are in the specification already
      if compname != name:
        allelems[elemref] = True
        allcomps[compname] = True
    for wireref in x.getElementsByTagName("from"): addelem(wireref)
    for wireref in x.getElementsByTagName("to"): addelem(wireref)

    # create the referenced element which will store the wiring information
    refd = dom.createElement("referenced")
    copy.appendChild(refd)
    for ref in allelems.keys():
      refd.appendChild(refidx[ref].cloneNode(True))
    for qname in allcomps.keys():
      refd.appendChild(qnameidx[qname].cloneNode(True))
    
    doc.appendChild(copy)
    ifile = file(filename, "w")
    doc.writexml(ifile)
    doc.unlink()
    ifile.close()
