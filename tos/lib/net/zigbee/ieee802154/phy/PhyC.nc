/*
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author Andre Cunha
 *
 */

#include "CC2420.h"
#include "IEEE802154.h"

configuration PhyC {

  provides interface SplitControl;
  
 // provides interface Test_send;
  
  
  //ieee802.15.4 phy interfaces
  provides interface PD_DATA;
  
  provides interface PLME_ED;
  provides interface PLME_CCA;
  provides interface PLME_SET;
  provides interface PLME_GET;
  provides interface PLME_SET_TRX_STATE;
  
}

implementation {

	components PhyP;
	
	components MainC;
	MainC.SoftwareInit -> PhyP;
	
	
	SplitControl = PhyP;
	
	//Test_send = PhyP;
	
	components CC2420ControlC;
	PhyP.Resource -> CC2420ControlC;
	PhyP.CC2420Power -> CC2420ControlC;
	PhyP.CC2420Config ->CC2420ControlC;
	
	components CC2420TransmitC;
	PhyP.SubControl -> CC2420TransmitC;
	
	PhyP.Sendframe ->CC2420TransmitC;
	
	components CC2420ReceiveC;
	
	//Receive = CC2420ReceiveC;
	
	
	PhyP.SubControl -> CC2420ReceiveC;
	
	
	PhyP.Receiveframe ->CC2420ReceiveC;
	
	
	components RandomC;
	PhyP.Random -> RandomC;
	
	components LedsC as Leds;
	PhyP.Leds -> Leds;
	
	
	PD_DATA=PhyP;
	
	PLME_ED=PhyP;
	PLME_CCA=PhyP;
	PLME_GET = PhyP;
	PLME_SET=PhyP;
	PLME_SET_TRX_STATE=PhyP;
}
