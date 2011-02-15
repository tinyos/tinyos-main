configuration PseudoSerialC {
  provides {
    interface StdControl;
    interface HdlcUart;
    interface PseudoSerial;
  }
} implementation {
  components PseudoSerialP;
  StdControl = PseudoSerialP;
  HdlcUart = PseudoSerialP;
  PseudoSerial = PseudoSerialP;
}
