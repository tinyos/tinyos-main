
Test the ability for the radio to duty cycle while sending and receiving
packets.  The radio should stop accepting requests, the SPI bus be released
properly, and the radio should shut down.

INSTALLATION
Transmitter is any mote with ID != 0
Receiver is any mote with ID == 0

EXPECTATIONS
The receiver duty cycles its radio faster than the transmitter.

Led0:
  Transmitter = cannot send

Led1:
  Transmitter = sent a message
  Receiver = received a message

Led2:
  On = radio on
  Off = radio off
  

