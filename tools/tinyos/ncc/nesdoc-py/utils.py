# Copyright (c) 2005 Intel Corporation
# All rights reserved.
#
# This file is distributed under the terms in the attached INTEL-LICENSE     
# file. If you do not find these files, copies can be found by writing to
# Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
# 94704.  Attention:  Intel License Inquiry.

# Miscellaneous utility functions (mostly for extracting information from XML)
from os import *
from xml.dom.minidom import *
from sys import *

# print an error message and exit
def nfail(s):
  stderr.write(s + "\n")
  exit(2)

# Create a directory without failing
def nmkdir(dir):
  try:
    mkdir(dir)
  except OSError:
    0

# Find the first element x of l for which f(x) is true
def nfind(f, l):
  for a in l:
    if f(a):
      return True
  return False

# True if a is in l
def nmember(a, l):
  return nfind(lambda (b): a == b, l)

# Return a sub-element with the specified tag
def xml_tag(x, tag):
  for child in x.childNodes:
    if child.nodeType == Node.ELEMENT_NODE and child.tagName == tag:
      return child
  return None

# Return some descendant with the specified tag
def xml_tagfind(x, tag):
  tmp = x.getElementsByTagName(tag)
  if len(tmp) == 1:
    return tmp[0]
  else:
    return None

# Return a sub-element with one of the specified tags
def xml_tagset(x, tags):
  for child in x.childNodes:
    if child.nodeType == Node.ELEMENT_NODE and nmember(child.tagName, tags):
      return child
  return None

# Return the ith sub-element
def xml_idx(x, i):
  for child in x.childNodes:
    if child.nodeType == Node.ELEMENT_NODE:
      if i == 0:
        return child
      i = i - 1
  return None

# Return all element children
def xml_elements(x):
  return filter(lambda (child): child.nodeType == Node.ELEMENT_NODE, x.childNodes)

# Join all CDATA children into a single string
def xml_text(x):
  str = ""
  for child in x.childNodes:
    if child.nodeType == Node.TEXT_NODE or child.nodeType == Node.CDATA_SECTION_NODE:
      str += child.data
  return str

