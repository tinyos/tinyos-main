# "Copyright (c) 2000-2003 The Regents of the University of California.  
# All rights reserved.
#
# Permission to use, copy, modify, and distribute this software and its
# documentation for any purpose, without fee, and without written agreement
# is hereby granted, provided that the above copyright notice, the following
# two paragraphs and the author appear in all copies of this software.
# 
# IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
# DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
# OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
# OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 
# THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
# ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
# PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
#
#                                                                      
# "Copyright (c) 2005 Stanford University. All rights reserved.
#
# Permission to use, copy, modify, and distribute this software and
# its documentation for any purpose, without fee, and without written
# agreement is hereby granted, provided that the above copyright
# notice, the following two paragraphs and the author appear in all
# copies of this software.
#
# IN NO EVENT SHALL STANFORD UNIVERSITY BE LIABLE TO ANY PARTY FOR
# DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
# ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
# IF STANFORD UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
# DAMAGE.
#
# STANFORD UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
# PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND STANFORD UNIVERSITY
# HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
# ENHANCEMENTS, OR MODIFICATIONS."
#
# @author Kamin Whitehouse 
# @author Philip Levis

from tinyos.tossim.TossimNescDecls import *

class NescVariables(object) :
  def __init__( self, applicationName="Unknown App", xmlFilename=None ) :
    self.applicationName = applicationName
    self._varNames = []
    self._vars = []

    dom = minidom.parse(xmlFilename)
    variableList = [node for node in dom.getElementsByTagName("variables")]
    while len(variableList) > 0:
      variables = variableList.pop(0).getElementsByTagName("variable")
      while len(variables) > 0:
        cVariable = 0
        isArray = 0

        variable = variables.pop(0)
        name = variable.getAttribute("name")
        component = variable.getElementsByTagName("component-ref")

        if (len(component) > 0):
          name = component[0].getAttribute("qname") + "." + name
        else:  # It's in a C file
          cVariable = 1
          fileName = variable.getAttribute("loc")
          index = fileName.rfind("/") # First check for a UNIX path
          if (index == -1):
            index = fileName.rfind("\\") # Then a windows path
            if (index == -1):
              index = fileName.rfind(":") # Then if it's in the local dir

          if (index != -1):
            fileName = fileName[index+1:]
            index = fileName.rfind(".")
            if (index != -1):
              fileName = fileName[0:index]
              name = fileName + "." + name

        varType = "unknown"
        varTypes = variable.getElementsByTagName("type-float")
        if (len(varTypes) == 0):
          varTypes = variable.getElementsByTagName("type-int")

        if (len(variable.getElementsByTagName("type-array")) > 0):
          isArray = 1
          
        if (len(varTypes) > 0):
          varTypeEntry = varTypes[0]
          varType = varTypeEntry.getAttribute("cname")

        if (cVariable == 0):
          self._varNames.append(str(name))
          self._vars.append(str(name))
          if (isArray):
            self._vars.append("array")
          else:
            self._vars.append("simple")
          self._vars.append(str(varType))
             
  def __str__(self) :
    """ Print all available variables."""
    string = "\n"
    name = 1
    for val in self._varNames :
      if (name):
        string += "\t" + val
        name = 0
      else:
        string += ": " + val + "\n"
        name = 1
        
    return string
     
  def variables(self):
    return self._vars
  

class NescTypes( object ) :
  """A class that holds all types defined in a specific nesc application.

  usage:
  myTypes = NescTypes('/path/to/nescDecls.xml')
  print myTypes
  var = myTypes.typeName
  """
  def __init__( self, applicationName="Unknown App", xmlFilename = None) :
    self.applicationName = applicationName
    self._typeNames = []
    self._types = {}
    #figure out the sizes of all the basic types for this platform (by scanning the xml file)
    platformTypes = {}
    typeRE = re.compile('cname=\"([\w\s]+?)\" size=\"I:(\d+?)\"')
    infile = open(xmlFilename, 'r')
    for line in infile :
      match = typeRE.search(line)
      if match != None:
        platformTypes[match.groups()[0]] = int(match.groups()[1])      
    #define all the basic types
    self.addType(
      nescType("uint8_t", "unsigned char", "int", "type-int", "B",1,0))
    self.addType(
      nescType("int8_t", "signed char", "int", "type-int", "b", 1, 0))
    if (platformTypes.has_key("int") and platformTypes["int"] == 4) or \
       (platformTypes.has_key("unsigned int") and platformTypes["unsigned int"] == 4) :
      self.addType(
        nescType("uint16_t", "unsigned short", "int", "type-int", "H", 2, 0))
      self.addType(
        nescType("int16_t", "short", "int", "type-int", "h", 2, 0))
      self.addType(
        nescType("uint32_t", "unsigned int", "int", "type-int", "L",4,0))
      self.addType(
        nescType("int32_t", "int", "int", "type-int", "L", 4, 0))
      self.addType(
        nescType("unsigned long", "unsigned long", "int", "type-int", "L",4,0))
      self.addType(
        nescType("long", "long", "int", "type-int", "l", 4, 0))
    else : #int is 2 bytes long (the default)
      self.addType(
        nescType("unsigned short", "unsigned short", "int", "type-int", "H", 2, 0))
      self.addType(
        nescType("short", "short", "int", "type-int", "h", 2, 0))
      self.addType(
        nescType("uint16_t", "unsigned int", "int", "type-int", "H", 2, 0))
      self.addType(
        nescType("int16_t", "int", "int", "type-int", "h", 2, 0))
      self.addType(
        nescType("uint32_t", "unsigned long", "int", "type-int", "L",4,0))
      self.addType(
        nescType("int32_t", "long", "int", "type-int", "l", 4, 0))
    self.addType(
      nescType("int64_t", "long long", "long", "type-int", "q", 8, 0))
    self.addType(
      nescType("uint64_t", "unsigned long long", "long", "type-int", "Q", 8, 0))
    self.addType(
      nescType("float", "float", "float", "type-float", "f", 4, 0))
    if platformTypes.has_key("double") and platformTypes["double"] == 8 :
      self.addType(
        nescType("double", "double", "float", "type-float", "d", 8, 0))
    else : #double is 4 bytes (the default)
      self.addType(
        nescType("double", "double", "float", "type-float", "f", 4, 0))
    self.addType(
      nescType("char", "char", "str", "type-int", "c", 1, '\x00'))
    self.addType(
      nescType("void", "void", "", "type-void", "", 0, ''))

    #some arrays for error reporting:
    self.unknownStructs = []
    self.anonymousStructs = []
    self.anonymousRefStructs = []
    self.undefinedTypes = []
    self.createTypesFromXml(xmlFilename)
    self._typeNames.sort()
    #self.printSkippedTypes()
  
  def addType(self, value) :
    if not value.nescType in self._typeNames :
      self._typeNames.append(value.nescType)
    self._types[value.nescType] = value #XXX: why does this have to be unconditional??
    if not self._types.has_key(value.cType):
      self._types[value.cType] = value
      self._typeNames.append(value.cType)
    
  def __getattr__(self, name) :
    if name in self._typeNames :
      return deepcopy(self._types[name])
    else:
      raise AttributeError("No type \"%s\" defined" % name)
  
  def __getitem__(self, key) :
    if key in self._typeNames :
      return deepcopy(self._types[key])
    else:
      raise AttributeError("No type \"%s\" defined" % key)

  def __repr__(self) :
    return "%s object at %s:\n\n\t%s" % (self.__class__, hex(id(self)), str(self))
    
  def __str__(self) :
    """ Print all available types."""
    string = "\n"
    for t in self._typeNames :
      string += "\t%s\n" % t
    return string
    
  def createTypesFromXml(self, xmlFilename) :
    """Go through the struct and typedef elements in the nescDecls.xml file"""
    
    dom = minidom.parse(xmlFilename)
    typeDefs = [node for node in dom.getElementsByTagName("struct")]
    for node in dom.getElementsByTagName("typedef") :
      typeDefs.append(node)
    
    numSkipped = 0

    #keep going through the queue until it is empty
    while len(typeDefs) > 0:
      typeDef = typeDefs.pop(0)

      #if this is a typedef, see if the value is there
      if typeDef.tagName == "typedef" :
        value = typeDef.getAttribute("value")
        name = typeDef.getAttribute("name")
        #if the real value exists and typedef doesn't already exist, copy and rename original
        if self._types.has_key(value) :
          newType = deepcopy(self._types[value])
          newType.nescType = name
          self.addType(newType)
          numSkipped=0
        else :
          #try again later
          typeDefs.append(typeDef)
          numSkipped += 1
          
      else :
        #if all types within the struct are already defined, it can be defined
        try :
          self.addType(nescStruct(self, typeDef ) )
          numSkipped=0

        except Exception, e:
          if len(e.args) > 0 and e.args[0] == "Undefined struct":
            #otherwise, put it back in the queue and move on to the next one
            typeDefs.append(typeDef)
            numSkipped += 1
          elif len(e.args) > 0 and e.args[0] == "Anonymous struct" :
            self.anonymousStructs.append(typeDef)
          elif len(e.args) > 0 and e.args[0] == "Anonymous struct reference" :
            self.anonymousRefStructs.append( (typeDef, e.args[1]) )
          elif len(e.args) > 0 and e.args[0] == "Unknown type" :
            self.unknownStructs.append( (typeDef, e.args[1]) )
          else :
            #if it's an unknown exception, reraise it
            raise
      
      #make sure we are not cycling endlessly
      if numSkipped >= len(typeDefs) > 0:
        self.undefinedTypes = typeDefs
        break

  def printSkippedTypes(self):
    err = ""
    if len(self.anonymousStructs) >0 :
      err += "\nWarning: %d structs were anonymous." % len(self.anonymousStructs)
#        for struc in anonymousStructs :
#            err += "\t%s\n" % struc.getAttribute("ref")
    if len(self.anonymousRefStructs) >0 :
      err += "\nWarning: The following structs referenced anonymous structs:\n"
      for pair in self.anonymousRefStructs :
        err += "\t%s\n" % pair[0].getAttribute("name")
    if len(self.undefinedTypes) >0 :
      err += "\nWarning: The following types are ill-defined or had circular dependencies:\n"
      for struc in self.undefinedTypes :
        err += "\t%s\n" % struc.getAttribute("name")
    if len(self.unknownStructs) >0 :
      err += "\nWarning: The following structs had unknown xml types:\n"
      for pair in self.unknownStructs :
        err += "\t%s (%s)\n" % (pair[0].getAttribute("name"),
                                pair[1].tagName )
    if len(err) > 0 : print err
    
  def getTypeFromXML(self, xmlDefinition) :
    """Find the type name value given an xml definition.
    If it is an array or pointer, define the new type here."""

    #first, see if the tag is type or if child is type
    if xmlDefinition.tagName.find("type-") < 0 or \
           xmlDefinition.tagName.find("type-qualified") >= 0 :
      foundType = 0
      childNodes = [node for node in xmlDefinition.childNodes
                    if node.nodeType == 1]
      for tag in childNodes :
        if tag.tagName.find("type-") >= 0 :
          foundType += 1
          typeTag = tag
      if foundType < 1 :
        raise Exception("No type tag found")
      if foundType > 1 :
        raise Exception("Too many type tags found")
      else :
        return self.getTypeFromXML(typeTag)

    #now check all the existing types to see if it is one of them
    for val in self._typeNames :
      typeObj = self._types[val]
      if typeObj.isType(xmlDefinition) :
        return deepcopy(typeObj)

    #if the type doesn't already exist, try creating a new one
    try :
      return nescArray(self, xmlDefinition)
    except Exception, e:
        if len(e.args) <= 0 or e.args[0] != "Not array definition":
          raise
    try :
      return nescPointer(self, xmlDefinition)
    except Exception, e:
        if len(e.args) <= 0 or e.args[0] != "Not pointer definition":
          raise
      
    #it is not a simple type, array, or pointer,
    #so it must be a yet undefined struct
    child = getUniqueChild(xmlDefinition)
    if ( xmlDefinition.tagName == "type-tag" and child != None and
         child.tagName == "struct-ref" ):
         if child.hasAttribute("name"):
             raise Exception("Undefined struct")
         else :
             raise Exception("Anonymous struct reference", child)
    else:
      #otherwise, raise an exception
      #(but first make sure the right kind of unknown type is displayed)
      if  xmlDefinition.tagName == "type-tag":
          xmlDefinition = child
      raise Exception("Unknown type", xmlDefinition)

class NescEnums( object ) :
  """A class that holds all enums defined in a specific nesc application.

  usage:
  myEnums = NescEnums('/path/to/nescDecls.xml')
  print myEnums
  var = myEnums.enumName
  """

  def __init__( self, applicationName="Unknown App", xmlFilename = None ) :
    self.applicationName = applicationName
    self._enums = []
    if type(xmlFilename) == str:
      xmlFilename = minidom.parse(xmlFilename)

    self.createEnumsFromXml(xmlFilename)

  def __getitem__(self, key) :
    if key in self._enums :
      return self.__dict__[key]
    else:
      raise AttributeError("No such enum defined")
      
  def createEnumsFromXml(self, dom) :

    #now define all the struct types
    enumDefs = [node for node in dom.getElementsByTagName("enum")]
    integer = re.compile('^I:(\d+)$')
    hexidecimal = re.compile('^(0x[\dabcdefABCDEF]+)$')
    
    for enumDef in enumDefs :
      name = enumDef.getAttribute("name")
      if name in self._enums :
        continue
      value = enumDef.getAttribute("value")
      match = integer.match(value)
      if match != None :
        self.__dict__[name] = int(match.groups()[0])
      else :
        match = hexidecimal.match(value)
        if match != None :
          self.__dict__[name] = int(match.groups()[0], 16)
        else :
          self.__dict__[name] = value
      self._enums.append(name)
      
    namedEnums = [node for node in dom.getElementsByTagName("namedEnum")]
    for namedEnum in namedEnums :
      name = namedEnum.getAttribute("name")
      self.__dict__[name] = NescEnums(namedEnum,name)
      self._enums.append(name)
    
  def __repr__(self) :
    return "%s object at %s:\n\n\t%s" % (self.__class__, hex(id(self)), str(self))
  
  def __str__(self) :
    """ Print all available enums."""
    string = "\n"
    for key in self._enums :
      string += "\t%s = %s\n" % (key, str(self[key]))
    return string
    

class NescMsgs( object ) :
  """A class that holds all msgs defined in a specific nesc application.
  It assumes a struct is a message if AM_STRUCTNAME is defined.

  usage:
  myMsgs = NescMsgs(myTypes, myEnums[, applicationName])
  print myMsgs
  var = myMsgs.msgName
  """
  def __init__( self, types, enums, applicationName="Unknown App" ) :
    self.applicationName = applicationName
    msgTypes = [enum for enum in enums._enums if enum.find("AM_") ==0]
    name = re.compile("^AM_(\w+)$")
    self._msgNames = []
    self._msgs = {}
    for msgType in msgTypes :
      if type(enums[msgType]) == int:
        msgName = name.match(msgType)
        if msgName != None :
          msgName = msgName.groups()[0]
        for key in types._typeNames :
          if key.lower() == msgName.lower() :
            msg = TosMsg(enums[msgType], types[key])
            self._msgs[key] = msg
            self._msgNames.append(key)
            break

  def __getattr__(self, name) :
    if name in self._msgNames :
      return deepcopy(self._msgs[name])
    else:
      raise AttributeError("No such message defined")
  
  def __getitem__(self, key) :
    if key in self._msgNames :
      return deepcopy(self._msgs[key])
    else:
      raise AttributeError("No such message defined")
      
  def __repr__(self) :
    return "%s object at %s:\n\n\t%s" % (self.__class__, hex(id(self)), str(self))
  
  def __str__(self) :
    """ Print all available msgs."""
    string = "\n"
    for key in self._msgNames :
      string += "\t%5d : %s\n" % (self._msgs[key].amType, key)
    return string
    

class NescApp( object ) :
  """A class that holds all types, enums, msgs, rpc commands and ram
  symbol definitions as defined for a specific nesc application.

  usage:
  myApp = nescApp('/path/to/nescDecls.xml')
  print myApp
  var = myApp.enums.enumName
  var = myApp.types.typeName
  """
  def __init__( self, applicationName="Unknown App", xmlFile="app.xml" ) :
    """This function creates the NescEnums, NescTypes, and NescMsgs
    objects for a particular application."""
    
    #first, import all enums, types, msgs, rpc functions, and ram symbols
    self.applicationName = applicationName
    self.xmlFile = xmlFile
    
    # Check for the nescDecls.xml file
    if not os.path.isfile(xmlFile):
      raise Exception("""\nERROR: cannot find file \"%s\".

Your nesC app cannot be imported.  Be sure that you compiled with the \"nescDecls\" option.\n\n""" % xmlFile)

    # Import enums, types, and msgs
    self.enums = NescEnums(applicationName, xmlFile)
    self.types = NescTypes(applicationName, xmlFile)
    self.variables = NescVariables(applicationName, xmlFile)
    self.messages = NescMsgs(self.types, self.enums, applicationName)

  def __repr__(self) :
    return "%s object at %s:\n\n%s" % (self.__class__, hex(id(self)), str(self))
  
  def __str__(self) :
    """ Print all application declarations."""
    string = "%20s : %d\n" % ("Enums", len(self.enums._enums))
    string += "%20s : %d\n" % ("Types", len(self.types._types))
    string += "%20s : %d\n" % ("Messages", len(self.messages._msgNames))
    string += "%20s : %d\n" % ("Variables", len(self.variables._varNames))
    return string

  def configureTossim(self):
    for var in variables:
      Mote.var
