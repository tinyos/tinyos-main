# Copyright (c) 2005 Intel Corporation
# All rights reserved.
#
# This file is distributed under the terms in the attached INTEL-LICENSE     
# file. If you do not find these files, copies can be found by writing to
# Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
# 94704.  Attention:  Intel License Inquiry.

# Generate HTML file for an interface

from nesdoc.utils import *
from nesdoc.generators import *
from nesdoc.html import *

__all__ = [ "generate_interface" ]

# A list of all functions with their short description, with links to the
# long description
def generate_fnlist_short(ht, name, fns):
  if len(fns) > 0:
    ht.tag("p")
    ht.heading(name)
    for fn in fns:
      ht.func_sig_start();
      ht.pfnsig(fn, lambda (name): '<a href="#%s">%s</a>' % (name, name))
      doc = nd_doc_short(fn)
      if doc != None:
        ht.push("menu")
        ht.pln(doc)
        ht.popln()
      ht.func_sig_stop();

# A list of all functions with their long description
def generate_fnlist_long(ht, name, fns):
  if len(fns) > 0:
    ht.tag("p")
    ht.heading(name + " - Details")
    first = True
    for fn in fns:
      if not first:
        ht.tag("hr")
      ht.startline()
      name = fn.getAttribute("name")
      ht.pln('<a name="%s"></a>' % name)
      ht.push("h4"); ht.p(name); ht.popln()
      ht.pfnsig(fn, lambda (name): '<b>%s</b>' % name)
      doc = nd_doc_long(fn)
      if doc:
        ht.startline(); ht.tag("p")
        ht.pushln("menu")
        ht.pdoc(doc)
        ht.popln()
      first = False

def generate_interface(intf):
  nicename = intf.getAttribute("nicename")
  ht = Html("ihtml/%s.html" % nicename )
  ht.title("Interface: " + nicename)
  ht.body()
  ht.push("h2");
  ht.pq("Interface: " + nicename)
  ht.pop()
  ht.startline()
  ht.push("b")
  parameters = xml_tag(intf, "parameters")
  ht.p("interface " + intf.getAttribute("qname"))
  if parameters:
    ht.p("&lt;" + parameter_str(parameters)[1:-1] + "&gt;")
  ht.pop()
  idoc =  nd_doc_long(intf)
  if idoc != None:
    ht.tag("p")
    ht.pdoc(idoc)
  ht.tag("p")

  functions = intf.getElementsByTagName("function")
  commands = filter(lambda (x): x.hasAttribute("command"), functions)
  events = filter(lambda (x): x.hasAttribute("event"), functions)
  commands.sort(lambda x, y: cmp(x.getAttribute("name").lower(), y.getAttribute("name").lower()));
  events.sort(lambda x, y: cmp(x.getAttribute("name").lower(), y.getAttribute("name").lower()));
  generate_fnlist_short(ht, "Commands", commands)
  generate_fnlist_short(ht, "Events", events)
  generate_fnlist_long(ht, "Commands", commands)
  generate_fnlist_long(ht, "Events", events)
  ht.close()
