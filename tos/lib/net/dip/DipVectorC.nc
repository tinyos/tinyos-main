
configuration DipVectorC {
  provides interface DipDecision;

  uses interface DipSend as VectorSend;
  uses interface DipReceive as VectorReceive;

  uses interface DipHelp;
  uses interface DipEstimates;
}

implementation {
  components DipVectorP;
  DipDecision = DipVectorP;
  VectorSend = DipVectorP;
  VectorReceive = DipVectorP;
  DipHelp = DipVectorP;
  DipEstimates = DipVectorP;

  components RandomC;
  DipVectorP.Random -> RandomC;

}
