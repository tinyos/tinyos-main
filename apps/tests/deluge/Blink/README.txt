README for apps/tests/deluge/Blink
Author/Contact:

Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
Razvan Musaloiu-E. <razvanm@cs.jhu.edu>

Description:

This is a sample application referenced in the Deluge T2 manual to show 
some of the basics in reprogramming.

The burn script performs the following tasks on the basestation:
   1) Compile and load the program normally.
   2) Compile another version of blink that blinks differently.
   3) Upload the new blink to flash volume 0.
   4) Instruct the mote to reprogram with the new blink.

Alternatively, you can reprogram the whole network (non-basestation 
motes) by first uploading the image to the base station. Then, tell the 
base station to disseminate the image. For example,

   tos-deluge /dev/ttyUSB0 telosb -d 0
   
Finally, after the image has been disseminated, instruct the base 
station to disseminate the command to reprogram. For example,

   tos-deluge /dev/ttyUSB0 telosb -r 0

For a more detailed discussion on Deluge T2, please refer to the Deluge 
T2 manual.

Prerequisites:

Python 2.4 with pySerial

References:

The Deluge T2 manual is available under $TOS_DIR/doc/html/.
