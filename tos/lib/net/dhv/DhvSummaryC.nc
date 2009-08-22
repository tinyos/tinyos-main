/**
 * DHV Summary Message Configuration.
 *
 * Define the interfaces and components.
 *
 * @author Thanh Dang
 * @author Seungweon Park
 *
 * @modified 1/3/2009   Added meaningful documentation.
 * @modified 8/28/2008  Defined DHV interfaces type.
 * @modified 8/28/2008  Took the source code from DIP.
 **/

configuration DhvSummaryC {
  provides interface DhvDecision;

  uses interface DhvSend as SummarySend;
  uses interface DhvReceive as SummaryReceive;
	uses interface DhvStateLogic as StateLogic;
  uses interface DhvHelp;
}

implementation {
  components DhvSummaryP;
  DhvDecision = DhvSummaryP;
  SummarySend = DhvSummaryP;
  SummaryReceive = DhvSummaryP;
	StateLogic = DhvSummaryP;
  DhvHelp = DhvSummaryP;
  components RandomC;
  DhvSummaryP.Random -> RandomC; 
}
