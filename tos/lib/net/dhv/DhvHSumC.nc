/**
 * DHV Horizontal Summary Implementation.
 *
 * Define the interfaces and components.
 *
 * @author Thanh Dang
 * @author Seungweon Park
 * @modified 1/3/2009   Added meaningful documentation.
 * @modified 8/28/2008  Defined DHV interfaces type.
 **/

configuration DhvHSumC{
  provides interface DhvDecision;

  uses interface DhvSend as HSumSend;
  uses interface DhvReceive as HSumReceive;
  uses interface DhvStateLogic as VBitLogic;
  uses interface DhvHelp;
}

implementation{	
  components DhvHSumP, RandomC;
  DhvDecision 		= DhvHSumP;
  HSumSend 		= DhvHSumP;
  HSumReceive 		= DhvHSumP;
  VBitLogic 		= DhvHSumP;
  DhvHelp 		= DhvHSumP;
  DhvHSumP.Random 	-> RandomC;
}
