README for apps/tests/deluge/GoldenImage
Author/Contact:

Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
Razvan Musaloiu-E. <razvanm@cs.jhu.edu>

Description:

This is a sample application for Deluge T2. The application is similar 
to Null, but it includes Deluge T2.

You can reprogram the whole network (non-basestation motes) by first 
uploading the image to the base station. Then, tell the base station to 
disseminate the image. Example:

   tos-deluge /dev/ttyUSB0 telosb -d 0
   
Finally, after the image has been disseminated, instruct the base 
station to disseminate the command to reprogram. Example:

   tos-deluge /dev/ttyUSB0 telosb -r 0

For a more detailed discussion on Deluge T2, please refer to the Deluge 
T2 manual.

Prerequisites:

Python 2.4 with pySerial

References:

The Deluge T2 manual is available under $TOS_DIR/doc/html/.
