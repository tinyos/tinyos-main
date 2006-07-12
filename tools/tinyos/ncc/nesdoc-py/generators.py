# Copyright (c) 2005 Intel Corporation
# All rights reserved.
#
# This file is distributed under the terms in the attached INTEL-LICENSE     
# file. If you do not find these files, copies can be found by writing to
# Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
# 94704.  Attention:  Intel License Inquiry.

# Two groups of functions
# A) Some functions to generate strings or HTML for various nesdoc entities
#    (end in _str or _html respectively)
# B) Utility functions and values for the nesdoc XML format

from xml.dom.minidom import *
from string import *
from nesdoc.utils import *

# All possible tags for types
type_tags = [
  "type-int",
  "type-float",
  "type-complex-int",
  "type-complex-float",
  "type-void",
  "type-qualified",
  "type-pointer",
  "type-array",
  "type-function",
  "type-tag",
  "type-interface",
  "type-component",
  "type-var" ]

# Return the long nesdoc string in x. If none is present, return the short
# nesdoc string. If no nesdoc string at all, return None.
def nd_doc_long(x):
  doc = xml_tag(x, "documentation")
  if not doc:
    return None
  str = xml_tag(doc, "long")
  if not str:
    str = xml_tag(doc, "short")
  return xml_text(str)

# Return the short nesdoc string in x. None if none present.
def nd_doc_short(x):
  doc = xml_tag(x, "documentation")
  if not doc:
    return None
  return xml_text(xml_tag(doc, "short"))

# find the first docstring in 's' at or after 'index'
# a docstring is an @ preceded by whitespace and followed by
# at least one letter
def _find_docstring_tag(s, index):
  while True:
    at = find(s, "@", index)
    if at <= 0: return at
    if at == len(s) - 1: return -1
    if s[at - 1].isspace() and s[at + 1].isalpha(): return at
    index = at + 1

# process a docstring s. returns a tuple of
#  - base documentation
#  - list of (tag, description) pairs (in the same order as in s)
def nd_docstring(s):
  tags = []
  at = _find_docstring_tag(s, 0)
  if at < 0:
    return (s, tags)
  base = s[:at]
  while at >= 0:
    # find end of tag
    tagend = at + 1
    while tagend < len(s) and not s[tagend].isspace():
      tagend += 1
    nextat = _find_docstring_tag(s, tagend)
    if nextat == -1:
      tagvalend = len(s)
    else:
      tagvalend = nextat
    tags.append((s[at + 1:tagend], s[tagend + 1:tagvalend]))
    at = nextat
  return (base, tags)

# return a string for contstant cstr (from a nesdoc XML constant attribute)
def nd_constant_str(cstr):
  if cstr[0] == 'I' or cstr[0] == 'F':
    return cstr[1:]
  elif cstr[0] == 'S':
    # XXX: should do a lot more.
    s = cstr[1:].replace('"', '\\"')
    return '"' + s + '"'
  elif cstr[0] == 'U':
    return "/* unknown */"
  elif cstr[0] == 'V':
    return "/* not-constant */"
  else:
    assert False

# Type encoders for the various kinds of types

def _typename_simple(xmltype, name, quals, isstar):
  return (quals + xmltype.getAttribute("cname"), name)

def _typename_void(xmltype, name, quals, isstar):
  return (quals + "void", name)

def _typename_qualified(xmltype, name, quals, isstar):
  silly = [quals]
  def add_qualifier(q):
    if xmltype.hasAttribute(q):
      silly[0] += q + " "
  add_qualifier("volatile")
  add_qualifier("const")
  add_qualifier("__restrict")
  return typename_full(xml_tagset(xmltype, type_tags), name, silly[0], isstar)

def _typename_ptr(xmltype, name, quals, isstar):
  name = "*" + quals + name
  return typename_full(xml_tagset(xmltype, type_tags), name, "", True)

def _typename_array(xmltype, name, quals, isstar):
  assert quals == ""
  if isstar:
    name = "(" + name + ")"
  size = xml_tag(xmltype, "elements")
  if size == "V":
    name += "[]"
  else:
    name += "[%s]" % constant_str(size)
  return typename_full(xml_tagset(xmltype, type_tags), name, "", False)

def _typename_tag(xmltype, name, quals, isstar):
  tagref = xml_idx(xmltype, 0)
  # the embedded element is named <tagkind>-ref
  head = "%s %s" % (tagref.tagName[:-4], tagref.getAttribute("name"))
  return (quals + head, name)

def _typename_var(xmltype, name, quals, isstar):
  varref = xml_idx(xmltype, 0)
  return (quals + varref.getAttribute("name"), name)

def _typename_fn(xmltype, name, quals, isstar):
  returntype = xml_idx(xmltype, 0)
  parameters = xml_idx(xmltype, 1)
  if isstar:
    name = "(" + name + ")"
  args = ""
  if parameters != None:
    for x in parameters.childNodes:
      if x.nodeType == Node.ELEMENT_NODE:
        ptype = typename_str(x, "")
        if args != "":
          args = args + ", "
        args += ptype
    if xmltype.hasAttribute("varargs"):
      args += ", ..."
  name += "(" + args + ")"
  if quals != "":
    name += quals[:-1] # remove trailing space
  return typename_full(returntype, name, "", False)

_type_printers = {
  "type-int" : _typename_simple,
  "type-float" : _typename_simple,
  "type-complex-int" : _typename_simple,
  "type-complex-float" : _typename_simple,
  "type-void" : _typename_void,
  "type-qualified" : _typename_qualified,
  "type-pointer" : _typename_ptr,
  "type-array" : _typename_array,
  "type-function" : _typename_fn,
  "type-tag" : _typename_tag,
  "type-interface" : _typename_tag,
  "type-component" : _typename_tag,
  "type-var" : _typename_var
  };

# Return a (head, body) pair for type xmltype, declaring name (a string)
# with type qualifiers quals (a string). isstar should be true if name
# starts with a *.
# The user-friendly representation for this type is head + " " + body
def typename_full(xmltype, name, quals, isstar):
  # hack around nesC 1.2.1 schema bug (uses typedef, not typename here)
  tdef = xml_tagset(xmltype, ["typedef", "typename"])
  if tdef:
    return (quals + xml_tag(tdef, "typedef-ref").getAttribute("name"), name)
  else:
    return _type_printers[xmltype.tagName](xmltype, name, quals, isstar)

# Return a user-friendly string for a C declaration of name with type xmltype
def typename_str(xmltype, name):
  (head, body) = typename_full(xmltype, name, "", False)
  if body == "":
    return head
  else:
    return head + " " + body

# Return a user-friendly string for a parameter list
def parameter_str(xmlparameters):
  args = ""
  if xmlparameters != None:
    for parm in xmlparameters.childNodes:
      if parm.nodeType == Node.ELEMENT_NODE:
        if args != "":
          args = args + ", "
        if parm.tagName == "variable" or parm.tagName == "constant":
          vtype = xml_tagset(parm, type_tags)
          args += typename_str(vtype, parm.getAttribute("name"))
        elif parm.tagName == "typedef":
          args += "typedef " + parm.getAttribute("name")
        elif parm.tagName == "varargs":
          args += ", ..."
  return "(" + args + ")"

# Return a user-friendly string for function xmlfn. The namedecorator
# function is called with the xmlfn's name as argument to get the final
# form of the function's name. Use this to, e.g., make the name an HTML link.
def function_signature_str(xmlfn, namedecorator):
  sig = ""
  if xmlfn.hasAttribute("command"):
    sig += "command "
  if xmlfn.hasAttribute("event"):
    sig += "event "
  type = xml_tag(xmlfn, "type-function")
  returntype = xml_idx(type, 0)
  name = xmlfn.getAttribute("name")
  parameters = xml_tag(xmlfn, "parameters")
  return sig + typename_str(returntype, namedecorator(name) + parameter_str(parameters))
