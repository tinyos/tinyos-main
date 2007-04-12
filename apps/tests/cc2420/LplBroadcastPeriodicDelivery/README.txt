Tx != 0
Rx == 0

This app sends a message from Tx to AM_BROADCAST_ADDR and waits 1000 ms between each delivery
so the Rx mote's radio shuts back off and has to redetect to receive the next
message.



EXPECTATIONS
Transmitter - always ID 1
  * Transmitting for 1000 ms, and then pause for 1000 ms.  
  * Broadcast address will not cut transmission short under any circumstances
  * Led0 indicates transmission
  * Transmitter receive check interval once every 1000 ms
  
Receiver - any other ID than 1
  * Receive check interval once every 1000 ms
  * Led1 indicates final reception

Led2 is left up to DutyCycleP to toggle when the radio is on.

