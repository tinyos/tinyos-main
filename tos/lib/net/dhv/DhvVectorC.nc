/**
 * DHV Vector Message Configuration
 *
 * Define interfaces and components.
 *
 * @author Thanh Dang
 * @author Seungweon Park
 *
 * @modified 1/3/2009   Added meaningful documentation.
 * @modified 8/28/2008  Defined DHV modules.
 * @modified 8/28/2008  Took the source code from DIP.
 **/

configuration DhvVectorC {
  provides interface DhvDecision;

  uses interface DhvSend as VectorSend;
  uses interface DhvReceive as VectorReceive;
  uses interface DhvLogic as VectorLogic;
	uses interface DhvLogic as DataLogic;
  uses interface DhvHelp;
}

implementation {
  components DhvVectorP;
  DhvDecision = DhvVectorP;
  VectorSend = DhvVectorP;
  VectorReceive = DhvVectorP;
  DhvHelp = DhvVectorP;
  VectorLogic = DhvVectorP.VectorLogic;
	DataLogic   = DhvVectorP.DataLogic;
  components RandomC;
  DhvVectorP.Random -> RandomC;

}
