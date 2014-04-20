/**
 * Generate a unique dsn byte for this outgoing packet
 * This should sit at the top of the stack
 * @author David Moss
 */
 
configuration UniqueSendC {
  provides {
    interface Send;
  }
  
  uses {
    interface Send as SubSend;
  }
}

implementation {
  components UniqueSendP,
      new StateC(),
      RandomC,
      CC2420PacketC,
      MainC;
      
  Send = UniqueSendP.Send;
  SubSend = UniqueSendP.SubSend;
  
  MainC.SoftwareInit -> UniqueSendP;
  
  UniqueSendP.State -> StateC;
  UniqueSendP.Random -> RandomC;
  UniqueSendP.CC2420PacketBody -> CC2420PacketC;
  
}

