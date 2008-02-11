/*
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author Andre Cunha
 *
 */

#include "CC2420.h"
#include "IEEE802154.h"

configuration Phy {

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

	components PhyM;
	
	components MainC;
	MainC.SoftwareInit -> PhyM;
	
	
	SplitControl = PhyM;
	
	//Test_send = PhyM;
	
	components CC2420ControlC;
	PhyM.Resource -> CC2420ControlC;
	PhyM.CC2420Power -> CC2420ControlC;
	PhyM.CC2420Config ->CC2420ControlC;
	
	components CC2420TransmitC;
	PhyM.SubControl -> CC2420TransmitC;
	
	PhyM.Sendframe ->CC2420TransmitC;
	
	components CC2420ReceiveC;
	
	//Receive = CC2420ReceiveC;
	
	
	PhyM.SubControl -> CC2420ReceiveC;
	
	
	PhyM.Receiveframe ->CC2420ReceiveC;
	
	
	components RandomC;
	PhyM.Random -> RandomC;
	
	components LedsC as Leds;
	PhyM.Leds -> Leds;
	
	
	PD_DATA=PhyM;
	
	PLME_ED=PhyM;
	PLME_CCA=PhyM;
	PLME_GET = PhyM;
	PLME_SET=PhyM;
	PLME_SET_TRX_STATE=PhyM;
}
