/**
* DHV header file.
*
* Define the interfaces and components.
*
* @author Thanh Dang
* @author Seungweon Park
*
* @modified 1/3/2009   Added meaningful documentation.
* @modified 8/28/2008  Defined DHV packet type and renamed the variable
* @modified 8/28/2008  Take the source code from Dip
**/



configuration DhvDataC {
  provides interface DhvDecision;

  uses interface DhvSend as DataSend;
  uses interface DhvReceive as DataReceive;

  uses interface DisseminationUpdate<dhv_data_t>[dhv_key_t key];
  uses interface DisseminationValue<dhv_data_t>[dhv_key_t key];
	
	uses interface DhvLogic as DataLogic;
	uses interface DhvLogic as VectorLogic;

  uses interface DhvHelp;
}

implementation {
  components DhvDataP;
  DhvDecision = DhvDataP;
  DataSend = DhvDataP;
  DataReceive = DhvDataP;
  DisseminationUpdate = DhvDataP;
  DisseminationValue = DhvDataP;
  DhvHelp = DhvDataP;
  DataLogic = DhvDataP.DataLogic;
	VectorLogic = DhvDataP.VectorLogic;

  components LedsC;
  DhvDataP.Leds -> LedsC;
}
