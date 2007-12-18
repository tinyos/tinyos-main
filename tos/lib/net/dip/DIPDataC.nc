
configuration DIPDataC {
  provides interface DIPDecision;

  uses interface DIPSend as DataSend;
  uses interface DIPReceive as DataReceive;

  uses interface DisseminationUpdate<dip_data_t>[dip_key_t key];
  uses interface DisseminationValue<dip_data_t>[dip_key_t key];

  uses interface DIPHelp;
  uses interface DIPEstimates;
}

implementation {
  components DIPDataP;
  DIPDecision = DIPDataP;
  DataSend = DIPDataP;
  DataReceive = DIPDataP;
  DisseminationUpdate = DIPDataP;
  DisseminationValue = DIPDataP;
  DIPHelp = DIPDataP;
  DIPEstimates = DIPDataP;

  components LedsC;
  DIPDataP.Leds -> LedsC;
}
