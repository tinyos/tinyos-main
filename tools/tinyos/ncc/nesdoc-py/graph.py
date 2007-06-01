# Copyright (c) 2005 Intel Corporation
# All rights reserved.
#
# This file is distributed under the terms in the attached INTEL-LICENSE     
# file. If you do not find these files, copies can be found by writing to
# Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
# 94704.  Attention:  Intel License Inquiry.

# Generate the picture and cmap for a configuration's wiring

from xml.dom.minidom import *
from nesdoc.utils import *
from nesdoc.generators import *
from sys import *
from os import system

def generate_component_graph(comp):
  generate_graph("chtml", "..", comp, xml_tag(comp, "wiring"),
                 comp.getAttribute("qname"), comp.getAttribute("nicename"))
  
def generate_graph(dir, repository, xml, wiring, name, nicename):
  if not wiring:
    return

  # Return the element definition for a given wiring endpoint
  def lookup_elem(endpoint):
    elemref = xml_tagset(endpoint, [ "interface-ref", "function-ref" ])
    return refidx[elemref.getAttribute("ref")]

  # Define nodes in a dot graph file. Each node is given a name, a graphic
  # style and a label. The elements map is updated to record the mapping
  # from XML node names ("ref" attribute) and dot-file node names.
  #   gf is the dot graph file
  #   wire is a wiring graph edge
  #   tag specifies which node to extract from wire (either "to" or "from")
  # Does nothing if the node has already been added.
  def add_node(gf, wire, tag):
    endpoint = xml_tag(wire, tag)
    elem = lookup_elem(endpoint)
    ref = elem.getAttribute("ref")
    if endpoints.has_key(ref): return
    
    compref = xml_tag(lookup_elem(endpoint), "component-ref")
    if compref.getAttribute("qname") == name:
      # reference to one's own interfaces become ellipses
      endpoints[ref] = "n%s" % ref
      gf.write('  %s [shape=ellipse, style=filled, label="%s", fontsize=12];\n' % (endpoints[ref], elem.getAttribute("name")))
    else:
      # references to interfaces or functions of other components become
      # a reference to a box representing that component.
      # each instance of a generic component gets a separate box.
      # there is a link to the component's own HTML file.

      ncompname = compref.getAttribute("qname")
      ncomp = compidx[ncompname]
      # Map this function or interface to the component (note that different
      # instances of generic components have different qnames)
      endpoints[ref] = ncompname

      # Define the component style. We may define it several times, but all
      # definitions are identical...
      gf.write('  "%s" ' % ncompname)
      styles = ["fontsize=12"]
      if xml_tag(ncomp, "configuration"):
        # configurations gets a double box
        styles.append("shape=box,peripheries=2")
      else:
        styles.append("shape=box")

      # Check for generic component instances
      instance = xml_tag(ncomp, "instance")
      if instance:
        # Make these dashed, with a label showing the generic component
        # and the instance name
        styles.append("style=dashed")
        iname = ncompname[find(ncompname, ".") + 1:]
        instanceof = xml_tag(instance, "component-ref")
        instanceof_name = instanceof.getAttribute("qname")
        if iname == instanceof_name:
          styles.append('label="%s"' % instanceof_name)
        else:
          styles.append('label="%s\\n(%s)"' % (instanceof_name, iname))
        styles.append('URL="%s/chtml/%s.html"' % (repository, instanceof.getAttribute("nicename")))
      else:
        # Just a regular component
        styles.append('URL="%s/chtml/%s.html"' % (repository, ncomp.getAttribute("nicename")))
      if styles != []:
        gf.write("[%s]" % join(styles, ", "))
      gf.write(";\n")
    
  
  def compname(endpoint):
    return endpoints[lookup_elem(endpoint).getAttribute("ref")]

  def wirestyle(endpoint):
    elem = lookup_elem(endpoint)
    if elem.tagName == "function":
      # missing: bold style for parameterised functions
      styles = ['label="%s"' % function_signature_str(elem, lambda (name): "X")]
    else:
      assert elem.tagName == "interface"
      instance = xml_tag(elem, "instance")
      idef = xml_tag(instance, "interfacedef-ref")
      arguments = xml_tag(instance, "arguments")
      parameters = xml_tag(elem, "interface-parameters")
      def_name = idef.getAttribute("qname")

      sig = def_name
      if arguments:
        iargs = join(map(lambda (arg): typename_str(arg, ""),
                         xml_elements(arguments)), ", ")
        sig += "<" + iargs + ">"
      if parameters:
        iparms = join(map(lambda (arg): typename_str(arg, ""),
                          xml_elements(parameters)),  ", ")
        sig += "[" + iparms + "]"
      styles = [ 'label="%s"' % sig ]
      if xml_tag(elem, "interface-parameters"):
        styles.append('style=bold')
      styles.append('URL="%s/ihtml/%s.html"' % (repository, idef.getAttribute("nicename")))
    styles.append("fontsize=10")
    return styles


  # build indices from ref attribute values to the corresponding elements
  refidx = {}
  compidx = {}
  for intf in xml.getElementsByTagName("interface"):
    refidx[intf.getAttribute("ref")] = intf
  for fn in xml.getElementsByTagName("function"):
    refidx[fn.getAttribute("ref")] = fn
  for ncomp in xml.getElementsByTagName("component"):
    compidx[ncomp.getAttribute("qname")] = ncomp
  
  # create the dot graph specification
  gf = file("%s/%s.dot" % (dir, nicename), "w")
  gf.write('digraph "%s" {\n' % nicename)
  
  endpoints = {}
  for wire in wiring.getElementsByTagName("wire"):
    add_node(gf, wire, "from")
    add_node(gf, wire, "to")
    
  for wire in wiring.getElementsByTagName("wire"):
    src = xml_tag(wire, "from")
    dest = xml_tag(wire, "to")
    gf.write('  "%s" -> "%s"' % (compname(src), compname(dest)))
    gf.write(' [%s];\n' % join(wirestyle(src), ", "))
  gf.write("}\n")
  gf.close()

  # Run dot twice to get a picture and cmap
  system("dot -Tpng -o%s/%s.png %s/%s.dot" % (dir, nicename, dir, nicename))
  system("dot -Tcmap -o%s/%s.cmap %s/%s.dot" % (dir, nicename, dir, nicename))
