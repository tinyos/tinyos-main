/*
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author Andre Cunha
 *
 */
#include <Timer.h>

#ifndef TKN154_MAC
#endif
#include "phy_const.h"
#include "phy_enumerations.h"
#include "mac_const.h"



#include "mac_enumerations.h"
#include "mac_func.h"
#include "nwk_func.h"
#include "nwk_enumerations.h"
#include "nwk_const.h"


configuration NWKC {

	//provides
	
	//NLDE NWK data service  
	
	provides interface NLDE_DATA;
	
	
	//NLME NWK Management service
	
	provides interface NLME_NETWORK_FORMATION;
	provides interface NLME_NETWORK_DISCOVERY;
	provides interface NLME_START_ROUTER;
	provides interface NLME_JOIN;
	provides interface NLME_LEAVE;
	
	/*     
	provides interface NLME_PERMIT_JOINING;
	provides interface NLME_DIRECT_JOIN;	*/
	provides interface NLME_RESET;
	
	provides interface NLME_SYNC;
	
	provides interface NLME_GET;
	provides interface NLME_SET;

}
implementation {

  components MainC;
  MainC.SoftwareInit -> NWKP;
  
  components LedsC;
  components NWKP;
       



  NWKP.Leds -> LedsC;
   
   
	components RandomC;
	NWKP.Random -> RandomC;


 
  //MAC interfaces
#ifndef TKN154_MAC

  components MacC;

  NWKP.MLME_START -> MacC.MLME_START;
  
  NWKP.MLME_GET ->MacC.MLME_GET;
  NWKP.MLME_SET ->MacC.MLME_SET;
  
  NWKP.MLME_BEACON_NOTIFY ->MacC.MLME_BEACON_NOTIFY;
  NWKP.MLME_GTS -> MacC.MLME_GTS;
  
  NWKP.MLME_ASSOCIATE->MacC.MLME_ASSOCIATE;
  NWKP.MLME_DISASSOCIATE->MacC.MLME_DISASSOCIATE;
  
  NWKP.MLME_ORPHAN->MacC.MLME_ORPHAN;
  NWKP.MLME_SYNC->MacC.MLME_SYNC;
  NWKP.MLME_SYNC_LOSS->MacC.MLME_SYNC_LOSS;
  NWKP.MLME_RESET->MacC.MLME_RESET;
  NWKP.MLME_SCAN->MacC.MLME_SCAN;
  
  NWKP.MCPS_DATA->MacC.MCPS_DATA;
#else


  components WrapperC;
  NWKP.MLME_RESET->WrapperC.OPENZB_MLME_RESET;
  NWKP.MLME_START -> WrapperC.OPENZB_MLME_START;
  
  NWKP.MLME_GET ->WrapperC.OPENZB_MLME_GET;
  NWKP.MLME_SET ->WrapperC.OPENZB_MLME_SET;
  
  NWKP.MLME_BEACON_NOTIFY ->WrapperC.OPENZB_MLME_BEACON_NOTIFY;
  NWKP.MLME_GTS -> WrapperC.OPENZB_MLME_GTS;
  
  NWKP.MLME_ASSOCIATE->WrapperC.OPENZB_MLME_ASSOCIATE;
  NWKP.MLME_DISASSOCIATE->WrapperC.OPENZB_MLME_DISASSOCIATE;
  
  NWKP.MLME_ORPHAN->WrapperC.OPENZB_MLME_ORPHAN;
  NWKP.MLME_SYNC->WrapperC.OPENZB_MLME_SYNC;
  NWKP.MLME_SYNC_LOSS->WrapperC.OPENZB_MLME_SYNC_LOSS;
  NWKP.MLME_SCAN->WrapperC.OPENZB_MLME_SCAN;
  
  NWKP.MCPS_DATA->WrapperC.OPENZB_MCPS_DATA;
#endif

///////////////
  	
	//NLDE NWK data service  
	NLDE_DATA=NWKP;
	
	//NLME NWK Management service
	NLME_NETWORK_FORMATION=NWKP;
	NLME_NETWORK_DISCOVERY=NWKP;
	
	NLME_START_ROUTER=NWKP;
	
	NLME_JOIN=NWKP;
	NLME_LEAVE=NWKP;
	
	/*
	NLME_PERMIT_JOINING=NWKP;
	NLME_DIRECT_JOIN=NWKP;*/
	NLME_RESET=NWKP;
	
	NLME_SYNC=NWKP;
	NLME_GET=NWKP;
	NLME_SET=NWKP;
	  
	  
}
