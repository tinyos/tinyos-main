# -*- python -*-
# Copyright (c) 2005 Intel Corporation
# All rights reserved.
#
# This file is distributed under the terms in the attached INTEL-LICENSE     
# file. If you do not find these files, copies can be found by writing to
# Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
# 94704.  Attention:  Intel License Inquiry.

# HTML generation from the XML files in a nesdoc repository.
#
# The HTML files are placed in three directories:
# - ihtml: HTML files for interfaces
# - chtml: HTML (and support) files for components
# - index: HTML index files
#
# HTML files for configurations include a wiring graph. Graphviz version 1.10
# (and, hopefully, later versions) are supported.
#
# Only components and interfaces in "packages" (i.e., with a package prefix
# in their nicename attribute - see nesdoc-archive) are indexed - files
# from applications are skipped. However, these files are still present in
# the ihtml and chtml directories

from nesdoc.utils import *
from nesdoc.interfaces import generate_interface
from nesdoc.components import generate_component
from nesdoc.graph import generate_component_graph
from nesdoc.index import generate_indices
from sys import *
from re import search, compile
from shutil import copyfile
import os
from nesdoc.html import *

param_pattern = compile("^\s*([a-zA-Z0-9_]+)")

# Print @param doc tags as Parameters:, and put parameter name as <code>
def param_doctag(val):
  name = param_pattern.search(val)
  if name:
    val = "<code>" + name.group(1) + "</code> - " + val[name.end():]
  return ("parameters", val)

# Print @return tags as Returns:
def return_doctag(val):
  return ("returns", val)
  
register_doctag("param", param_doctag)
register_doctag("return", return_doctag)

# Generate HTML files, and a global index for all interfaces and components
# in the specified repository
if argv[1] == "--quiet":
  repository = argv[2]
  quiet = True
else:
  repository = argv[1]
  quiet = False

try:
  chdir(repository)
  
  # set up directories
  nmkdir("ihtml")
  nmkdir("chtml")
  nmkdir("index")

  # copy stylesheet
  pathname = os.path.abspath(os.path.dirname(argv[0]))
  copyfile(pathname + "/nesdoc.css", "chtml/nesdoc.css")
  copyfile(pathname + "/nesdoc.css", "ihtml/nesdoc.css")
  copyfile(pathname + "/nesdoc.css", "index/nesdoc.css")
  copyfile(pathname + "/nesdoc.css", "nesdoc.css")

  compfiles = listdir("components")
  intffiles = listdir("interfaces")
  
except OSError:
  nfail("Couldn't access nesdoc repository " + repository)

for intf in intffiles:
  if search("\\.xml$", intf):
    if not quiet:
      stderr.write("interface " + intf + "\n")
    ixml = parse("interfaces/" + intf)
    generate_interface(ixml.documentElement)
    ixml.unlink()

for comp in compfiles:
  if search("\\.xml$", comp):
    if not quiet:
      stderr.write("component " + comp + "\n")
    ixml = parse("components/" + comp)
    generate_component_graph(ixml.documentElement)
    generate_component(ixml.documentElement)
    ixml.unlink()

generate_indices(compfiles, intffiles)
