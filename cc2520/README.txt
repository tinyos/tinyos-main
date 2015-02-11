
To compile in the default Ack LPL version, #define the preprocessor variable:
  LOW_POWER_LISTENING
  
To compile in the PacketLink (auto-retransmission) layer, #define:
  PACKET_LINK
  
To remove all acknowledgements, #define (or use CC2420Config in 2.0.2)
  CC2420_NO_ACKNOWLEDGEMENTS
  
To use hardware auto-acks instead of software acks, #define:
  CC2420_HW_ACKNOWLEDGEMENTS

To stop using address recognition on the radio hardware, #define:
  CC2420_NO_ADDRESS_RECOGNITION



============================================================
CC2420 2.0.2 Release Notes 7/2/07

Updates (Moss)
__________________________________________
* New chip SPI bus arbitration working with Receive and Transmit.

* Applied TUnit automated unit testing to CC2420 development
  > Caught lots of bugs, especially through regression testing
  > Source code in tinyos-2.x-contribs/tunit/

* Applied TEP115 behavior to CC2420 SplitControl in Csma and Lpl

* Updated ActiveMessageAddressC to provide the ActiveMessageAddress interface
  > Updated CC2420ConfigP to handle ActiveMessageAddress.addressChanged() and
    sync automatically upon address change events.

* Updated CC2420Config interface to enable/disable sw/hw acknowledgements

* Updated CC2420ConfigP to share register editing through single functions

* Acknowledge after packet length and FCF check out valid.  
  > The destination address is confirmed in hardware, so we don't need 
    to download the entire header before acking.

* Moved the getHeader() and getMetadata() commands to an internal interface
  called CC2420PacketBody, provided by CC2420PacketC

* Separated core functionality into different sub-packages/directories
  > Updated micaz, telosb, intelmote2 .platform files
  > Logically organizes code

* Updated some LPL architecture
  > Removed continuous modulation because it didn't work 100% and I don't have 
    time to make it work.  
  > Decreased backoffs and decreased on-time for detects, saving energy.

* Updated to the new AMPacket interface; made the radio set the outbound
  packet's destpan after send().


7/5/07:
* Added two methods to enable/disable automatic address recognition:
  - Preprocessor CC2420_NO_ADDRESS_RECOGNITION to disable address recognition at
    compile time
  - CC2420Config.setAddressRecognition(bool on) through CC2420ControlC

* Allowed the CC2420ReceiveP to perform software address checks to support
  the case where a base station type application must sniff packets from other 
  address, but also SACK packets destined for its address
  
* Updated CC2420Config interface to provide an async getShortAddr() and getPanAddr()


Known issues
__________________________________________




============================================================
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
The default is called "AckLpl", because it inserts acknowledgement gaps andshort backoffs during the packet retransmission process. 
This allows the transmitter to stop transmitting early, but increases the 
power consumption per receive check.  This is better for slow receive
check, high transmission rate networks.

The second is called "NoAckLpl", because it does not insert acknowledgement
gaps or backoffs in the retransmission process, so the receive checks are 
shorter but the transmissions are longer.  This is more experimental than
the Ack LPL version.  The radio continuously modulates the channel when
delivering its packetized preamble.  This is better for fast receive check,
low transmission rate networks.

