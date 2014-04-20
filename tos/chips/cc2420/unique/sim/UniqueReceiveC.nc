/**
 * This layer keeps a history of the past RECEIVE_HISTORY_SIZE received messages
 * If the source address and dsn number of a newly received message matches
 * our recent history, we drop the message because we've already seen it.
 * This should sit at the bottom of the stack
 * @author David Moss
 */
 
configuration UniqueReceiveC {
  provides {
    interface Receive;
    interface Receive as DuplicateReceive;
  }
  
  uses {
    interface Receive as SubReceive;
  }
}

implementation {
  components UniqueReceiveP,
      CC2420PacketC,
      MainC;
  
  Receive = UniqueReceiveP.Receive;
  DuplicateReceive = UniqueReceiveP.DuplicateReceive;
  SubReceive = UniqueReceiveP.SubReceive;
      
  MainC.SoftwareInit -> UniqueReceiveP;
  
  UniqueReceiveP.CC2420PacketBody -> CC2420PacketC;
  
}

