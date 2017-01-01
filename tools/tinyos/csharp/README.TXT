
DESCRIPTION

  This is a TinyOS SDK implementation written in C#. 
  The solution includes the following projects:

  - tinyos-sdk: Class library project which compiles into a single `.dll` file
    that can be referenced from any C# project.

  - sfsharp: Serial Forwarder built on top of the sdk which combines in the 
    same command shell features from both the Java SF and the C++ SF:

      *	`start`,`stop`,`info` and `list` commands. Mote interface for the 
        SF-Servers can be Serial and TCP
      *	`send` and `listen` commands integrated in the program shell
      *	Local and control client
      *	Command history and inline command editing

  - ExampleTelosB: Usage example. Simple application that reads, converts and 
    displays sensor values from telosB nodes.

  - TestSerial: Usage example. An implementation of the TestSerial application

DEPENDENCIES

  - Microsoft .NET v3.5 or higher
  
INSTALL

  - Run the build.bat file or open the solution with Visual Studio
  
LICENSE
  
  Copyright (c) 2013, ADVANTIC Sistemas y Servicios S.L.
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification,
  are permitted provided that the following conditions are met:

    Redistributions of source code must retain the above copyright notice, this
    list of conditions and the following disclaimer.

    Redistributions in binary form must reproduce the above copyright notice, this
    list of conditions and the following disclaimer in the documentation and/or
    other materials provided with the distribution.

    Neither the name of the ADVANTICSYS nor the names of its
    contributors may be used to endorse or promote products derived from
    this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
  
CONTACT 

  Eloy Díaz <eldial@gmail.com>