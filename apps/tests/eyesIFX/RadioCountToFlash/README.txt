README for RadioCountToFlash

Description:

RadioCountToLeds maintains a 1Hz counter and broadcsts its value repeatedly. A 
RadioCountToLeds node that hears a counter writes the counter to the flash. 
After LOG_LENGTH (default = 16) successful receiptions the previously stored counters 
are read from the flash with a delay of 100ms between each read. The bottom three bits 
are displayed on the LEDs. This application tests the coexistance between 
the radio and the flash.

Tools:

RadioCountMsg.java is a Java class representing the message that
this application sends.  RadioCountMsg.py is a Python class representing
the message that this application sends.

Known bugs/limitations:

None.


