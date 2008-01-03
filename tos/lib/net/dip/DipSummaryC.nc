
configuration DipSummaryC {
  provides interface DipDecision;

  uses interface DipSend as SummarySend;
  uses interface DipReceive as SummaryReceive;

  uses interface DipHelp;
  uses interface DipEstimates;
}

implementation {
  components DipSummaryP;
  DipDecision = DipSummaryP;
  SummarySend = DipSummaryP;
  SummaryReceive = DipSummaryP;
  DipHelp = DipSummaryP;
  DipEstimates = DipSummaryP;

  components RandomC;
  DipSummaryP.Random -> RandomC; 
}
