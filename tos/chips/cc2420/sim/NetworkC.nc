configuration NetworkC
{
  provides {
    interface SplitControl as Control;
    interface TossimPacketModel as Model;
    interface PacketAcknowledgements as Acks;
  }
}

implementation
{
  components MainC;
  components TossimPacketModelC as Network;
  components CpmModelC;

  MainC.SoftwareInit -> Network;
  Model = Network;
  Control = Network;
  Acks = Network;
  Network.GainRadioModel -> CpmModelC;
}
