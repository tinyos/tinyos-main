# Copyright (c) 2005 Intel Corporation
# All rights reserved.
#
# This file is distributed under the terms in the attached INTEL-LICENSE     
# file. If you do not find these files, copies can be found by writing to
# Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
# 94704.  Attention:  Intel License Inquiry.

# An HTML output class, with convenience routines for handling tags and
# indentation.

from string import *
from nesdoc.generators import *
from re import search

_doctags = {}

def register_doctag(name, handler):
  _doctags[name] = handler

class Html:
  # create a new HTML output file in filename
  def __init__(self, filename):
    self.f = file(filename, "w")
    self.tags = []
    self.ind = 0
    self.at0 = True
    self.pushln("html");
    self.pushln("head");
    # include stylesheet
    self.tag("LINK", "rel=\"stylesheet\"", "href=\"nesdoc.css\"", "type=\"text/css\"", "media=\"screen\"")

  # end of html generation. cleanup and close the underlying file.
  def close(self):
    self.popln()
    self.popln()
    assert self.ind == 0 and self.tags == []
    self.f.close()

  def indent(self):
    self.ind += 2

  def unindent(self, ):
    self.ind -= 2

  # print a string
  def p(self, s):
    if self.at0:
      self.f.write(" " * self.ind)
      self.at0 = False
    self.f.write(s)

  # print a string and end the line
  def pln(self, s):
    self.p(s)
    self.f.write("\n")
    self.at0 = True

  # print a string, quoting the characters with meaning in HTML
  def pq(self, s):
    s.replace("<", "&lt;")
    s.replace(">", "&gt;")
    s.replace("&", "&amp;")
    s.replace('"', "&quot;")
    self.p(s)

  # newline if not at the start of a line
  def startline(self):
    if not self.at0:
      self.pln("")

  # start a new tag
  def push(self, tag, *attrs):
    self.tag(tag, *attrs)
    self.tags.append(tag)
    self.indent()

  # start a new tag on a new line
  def pushln(self, tag, *attrs):
    self.startline();
    self.tag(tag, *attrs)
    self.pln("")
    self.tags.append(tag)
    self.indent()

  # print a tag, but don't save it on the tag stack
  def tag(self, tag, *attrs):
    if attrs == ():
      self.p("<%s>" % tag)
    else:
      self.p("<%s %s>" % (tag, join(attrs)))

  # print a tag on a new line, but don't save it on the tag stack
  def tagln(self, tag, *attrs):
    self.tag(tag, *attrs)
    self.pln("")
    
  # pop and print a terminator the most recent tag from the tag stack
  def pop(self):
    self.unindent()
    self.p("</%s>" % self.tags.pop())

  # pop and print (on a new line) a terminator the most recent tag from the
  # tag stack
  def popln(self):
    self.unindent()
    self.startline()
    self.pln("</%s>" % self.tags.pop())

  # print the HTML title
  def title(self, s):
    self.push("title");
    self.pq(s);
    self.pop();

  # start the body section
  def body(self):
    self.popln() # pop head
    self.pushln("body")

  # Highlevel methods

  # escape <> enclosed email addresses
  def escape_email(self, s):
    while True:
      email = search("<\S+@\S+>", s)
      if not email:
        break
      start = email.start()
      end = email.end()
      s = s[:start] + "&lt;" + s[start + 1 : end - 1] + "&gt;" + s[end:]
    return s

  # print a nesdoc string. @ entries go in a table
  def pdoc(self, docstr):
    (base, tags) = nd_docstring(docstr)
    self.pln(self.escape_email(base))
    if tags:
      self.tag("p")
      self.pushln("dl")
      lasttag = None
      for (tag, val) in tags:
        if _doctags.has_key(tag):
          (tag, val) = _doctags[tag](val)
        if tag != lasttag:
          self.tag("dt");
          self.push("b"); self.pq(capitalize(tag) + ":"); self.pop()
        self.pushln("dd");
        self.p(self.escape_email(val))
        self.popln() #dd
        lasttag = tag
      self.popln() #dl

  # print a nice fancy heading
  def heading(self, s):
    self.push("div", "id=heading")
    self.pq(s)
    self.pop();

  def func_sig_start(self) :
    self.push("div", "id=funcsig")

  def func_sig_stop(self) :
    self.pop();

  # print a function signature. namedecorator is called with the function
  # name as argument so that you can decorate the actual function name
  # (e.g., bold, a link)
  def pfnsig(self, fn, namedecorator):
    self.push("span", "id=funcnameshort")
    self.pln(function_signature_str(fn, namedecorator))
    self.pop()
