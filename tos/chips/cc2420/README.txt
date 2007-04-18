
CC2420 Release Notes 4/11/07

This CC2420 stack contains two low power listening strategies,
a packet retransmission layer, unique send and receive layers,
ability to specify backoff and use of clear channel assessments
on outbound messages, direct RSSI readings, ability to change 
channels on the fly, an experimental 6LowPAN layer (not
implemented by default), general bug fixes, and more.


Known Issues
__________________________________________
 > LPL Lockups when the node is also accessing the USART.
   This is a SPI bus issue, where shutting off the SPI
   bus in the middle of an operation may cause the node
   to hang.  Look to future versions on CVS for the fix.

 > NoAck LPL doesn't ack at the end properly, and also isn't
   finished being implemented. The CRC of the packet needs to 
   manually be loaded into TXFIFO before continuous modulation.

 > LPL stack is optimized for reliability at this point, since
   SFD sampling is not implemented in this version.  
 

Low Power Listening Schemes and Preprocessor Variables
__________________________________________
There are two low power listening schemes.  
The default is called "AckLpl", because it inserts acknowledgement gaps and
short backoffs during the packet retransmission process. 
This allows the transmitter to stop transmitting early, but increases the 
power consumption per receive check.  This is better for slow receive
check, high transmission rate networks.

The second is called "NoAckLpl", because it does not insert acknowledgement
gaps or backoffs in the retransmission process, so the receive checks are 
shorter but the transmissions are longer.  This is more experimental than
the Ack LPL version.  The radio continuously modulates the channel when
delivering its packetized preamble.  This is better for fast receive check,
low transmission rate networks.

To compile in the default Ack LPL version, #define the preprocessor variable:
  LOW_POWER_LISTENING
 -or-  
  ACK_LOW_POWER_LISTENING (default)
  

To compile in experimental NoAck LPL w/continuous modulation, #define:
  NOACK_LOW_POWER_LISTENING

  
To compile in the PacketLink (auto-retransmission) layer, #define:
  PACKET_LINK
  

To remove all acknowledgements, #define:
  CC2420_NO_ACKNOWLEDGEMENTS
  

To use hardware auto-acks instead of software acks, #define:
  CC2420_HW_ACKNOWLEDGEMENTS


