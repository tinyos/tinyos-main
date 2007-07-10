README for RadioSenseToLeds
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

RadioSenseToLeds samples a platform's default sensor at 4Hz and broadcasts
this value in an AM packet. A RadioSenseToLeds node that hears a broadcast 
displays the bottom three bits of the value it has received. This application 
is a useful test to show that basic AM communication, timers, and the default 
sensor work.

Tools:

After compiling, RadioSenseMsg.java and RadioSenseMsg.py files will be
created.  RadioSenseMsg.java is a Java class representing the message that
this application sends.  RadioSenseMsg.py is a Python class representing
the message that this application sends.

Known bugs/limitations:

None.


$Id: README.txt,v 1.5 2007-07-10 20:03:30 klueska Exp $
