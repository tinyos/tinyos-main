
configuration DIPVectorC {
  provides interface DIPDecision;

  uses interface DIPSend as VectorSend;
  uses interface DIPReceive as VectorReceive;

  uses interface DIPHelp;
  uses interface DIPEstimates;
}

implementation {
  components DIPVectorP;
  DIPDecision = DIPVectorP;
  VectorSend = DIPVectorP;
  VectorReceive = DIPVectorP;
  DIPHelp = DIPVectorP;
  DIPEstimates = DIPVectorP;

  components RandomC;
  DIPVectorP.Random -> RandomC;

}
