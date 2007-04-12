Tx != 0
Rx == 0

This app sends a message from Tx to 0 and waits 1000 ms between each delivery
so the Rx mote's radio shuts back off and has to redetect to receive the next
message.



EXPECTATIONS
Transmitter #1
  * Transmitting for 1000 ms, and then pause for 1000 ms.  
  * Will cut transmission short if using Ack LPL and the receiver gets the msg
  * Led0 indicates transmission
  * Transmitter receive check interval once every 1000 ms
  
Receiver #0
  * Receive check interval once every 1000 ms
  * Led1 indicates final reception

Led2 is left up to DutyCycleP to toggle when the radio is on.

