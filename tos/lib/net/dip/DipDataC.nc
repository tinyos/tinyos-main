
configuration DipDataC {
  provides interface DipDecision;

  uses interface DipSend as DataSend;
  uses interface DipReceive as DataReceive;

  uses interface DisseminationUpdate<dip_data_t>[dip_key_t key];
  uses interface DisseminationValue<dip_data_t>[dip_key_t key];

  uses interface DipHelp;
  uses interface DipEstimates;
}

implementation {
  components DipDataP;
  DipDecision = DipDataP;
  DataSend = DipDataP;
  DataReceive = DipDataP;
  DisseminationUpdate = DipDataP;
  DisseminationValue = DipDataP;
  DipHelp = DipDataP;
  DipEstimates = DipDataP;

  components LedsC;
  DipDataP.Leds -> LedsC;
}
