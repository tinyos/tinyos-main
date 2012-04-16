$Id: README.txt,v 1.4 2006-12-12 18:22:52 vlahan Exp $

README for Printf

Author/Contact:

  tinyos-help@millennium.berkeley.edu

Description:

   This application is used to test the basic functionality of the
   printf service. After starting the service, calls to the standard
   c-style printf command are made to print various strings of text
   over the serial line. The output can be displayed using the
   PrintfClient, for example using the following command line:

   java net.tinyos.tools.PrintfClient -comm serial@/dev/ttyUSB0:115200

   Successful execution of the application is indicated by repeated
   output of the following string sequence:
   
   Hi I am writing to you from my TinyOS application!!
   Here is a uint8: 123
   Here is a uint16: 12345
   Here is a uint32: 1234567890
   ...

Tools:

  net.tinyos.tools.PrintfClient

Known bugs/limitations:

  None.
