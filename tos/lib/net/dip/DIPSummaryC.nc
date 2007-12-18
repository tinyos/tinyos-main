
configuration DIPSummaryC {
  provides interface DIPDecision;

  uses interface DIPSend as SummarySend;
  uses interface DIPReceive as SummaryReceive;

  uses interface DIPHelp;
  uses interface DIPEstimates;
}

implementation {
  components DIPSummaryP;
  DIPDecision = DIPSummaryP;
  SummarySend = DIPSummaryP;
  SummaryReceive = DIPSummaryP;
  DIPHelp = DIPSummaryP;
  DIPEstimates = DIPSummaryP;

  components RandomC;
  DIPSummaryP.Random -> RandomC; 
}
