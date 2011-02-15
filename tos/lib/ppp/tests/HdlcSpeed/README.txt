The HdlcSpeed application prints a text configuration specification, then
awaits a series of frame exchanges, measuring the time it takes to process
them and any errors encountered.

The green LED will toggle on each received frame; the blue LED will togle on
each sent frame.  If an error is encountered, the red LED will be lit; it is
likely that the experiment will desynchronize and stop at this point.
Certain errors can only be detected on platforms that support the
Msp430UsciError interface in PlatformSerialC.

The following extras are recognized:

- fdx : After receiving the first frame, the application will continually
  transmit its without synchronization.  If omitted, the application will
  only transmit a frame after it has received one.

- reps,n : The number of frames transmitted by each side.

- frame,n : The length of the frame, in octets.  Do not exceed the size
  specified in the HdlcFramingC component in TestAppC.nc.  In practice,
  errors are significantly more likely as the frame length increases.

- dco,n : Set the DCO speed in megahertz.  This option probably only works
  on SuRF, but increases the reliability of the interrupt-driven UART on
  that platform.

An example test:

make surf osian dco,16 fdx reps,10 frame,200 install
python gendata.py
