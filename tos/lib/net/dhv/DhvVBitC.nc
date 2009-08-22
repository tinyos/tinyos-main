/**
 * DHV Virtual Bits Check Configuration
 *
 * Define interfaces and components.
 *
 * @author Thanh Dang
 * @author Seungweon Park
 *
 * @modified 1/3/2009   Added meaningful documentation.
 * @modified 8/28/2008  Defined DHV modules.
 **/

configuration DhvVBitC{
	provides interface DhvDecision;
	
	uses interface DhvSend as VBitSend;
	uses interface DhvReceive as VBitReceive;
	uses interface DhvStateLogic as VBitLogic;
	uses interface DhvLogic as VectorLogic;
	uses interface DhvHelp;
}

implementation{
	
	components DhvVBitP;
	DhvDecision = DhvVBitP;
	VBitSend 		= DhvVBitP;
	VBitReceive = DhvVBitP;
	VBitLogic 	= DhvVBitP;
	VectorLogic = DhvVBitP;
	DhvHelp 		= DhvVBitP;

	components RandomC;
	DhvVBitP.Random -> RandomC;
}
