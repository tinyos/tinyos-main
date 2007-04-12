
CC2420 Release Notes 4/11/07

Known Issues
__________________________________________
 > LPL Lockups when the node is also accessing the USART
 > NoAck LPL doesn't ack at the end properly, and also isn't
   finished being implemented. The CRC of the packet needs to 
   manually be loaded into TXFIFO before continuous modulation.
 

Low Power Listening Schemes and Preprocessor Variables
__________________________________________
There are two low power listening schemes.  
The default is called "AckLpl", because it inserts acknowledgement gaps and
short backoffs during the packet retransmission process.  
This allows the transmitter to stop transmitting early, but increases the 
power consumption per receive check.  

The second is called "NoAckLpl", because it does not insert acknowledgement
gaps or backoffs in the retransmission process, so the receive checks are 
shorter but the transmissions are longer.  This is more experimental than
the Ack LPL version.

To compile in the default Ack LPL version, #define the preprocessor variable:

  LOW_POWER_LISTENING
 -or-  
  ACK_LOW_POWER_LISTENING
  
  
To compile in the NoAck LPL version, #define:

  NOACK_LOW_POWER_LISTENING

  
To compile in the PacketLink layer, #define:

  PACKET_LINK
  
  
To remove SACK auto-acknowledgements, #define:

  CC2420_NO_ACKNOWLEDGEMENTS
  
