/*
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author Andre Cunha
 *
 */
#include <Timer.h>

#include "phy_const.h"
#include "phy_enumerations.h"
#include "mac_const.h"
#include "mac_enumerations.h"
#include "mac_func.h"

#include "nwk_func.h"
#include "nwk_enumerations.h"
#include "nwk_const.h"


configuration NWK {

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
	provides interface NLME_DIRECT_JOIN;		
	provides interface NLME_RESET;
	*/
	provides interface NLME_SYNC;
	
	provides interface NLME_GET;
	provides interface NLME_SET;

}
implementation {

  components MainC;
  MainC.SoftwareInit -> NWKM;
  
  components LedsC;
  components NWKM;
       
  components Mac;
  
  NWKM.Leds -> LedsC;
   
   
	components RandomC;
	NWKM.Random -> RandomC;
   
   
  //MAC interfaces
  
  NWKM.MLME_START -> Mac.MLME_START;
  
  NWKM.MLME_GET ->Mac.MLME_GET;
  NWKM.MLME_SET ->Mac.MLME_SET;
  
  NWKM.MLME_BEACON_NOTIFY ->Mac.MLME_BEACON_NOTIFY;
  NWKM.MLME_GTS -> Mac.MLME_GTS;
  
  NWKM.MLME_ASSOCIATE->Mac.MLME_ASSOCIATE;
  NWKM.MLME_DISASSOCIATE->Mac.MLME_DISASSOCIATE;
  
  NWKM.MLME_ORPHAN->Mac.MLME_ORPHAN;
  NWKM.MLME_SYNC->Mac.MLME_SYNC;
  NWKM.MLME_SYNC_LOSS->Mac.MLME_SYNC_LOSS;
  NWKM.MLME_RESET->Mac.MLME_RESET;
  
  NWKM.MLME_SCAN->Mac.MLME_SCAN;
  
  
  NWKM.MCPS_DATA->Mac.MCPS_DATA;
	
	
	
	//NLDE NWK data service  
	NLDE_DATA=NWKM;
	
	//NLME NWK Management service
	NLME_NETWORK_FORMATION=NWKM;
	NLME_NETWORK_DISCOVERY=NWKM;
	
	NLME_START_ROUTER=NWKM;
	
	NLME_JOIN=NWKM;
	NLME_LEAVE=NWKM;
	
	/*
	NLME_PERMIT_JOINING=NWKM;
	NLME_DIRECT_JOIN=NWKM;
	NLME_RESET=NWKM;
	*/
	NLME_SYNC=NWKM;
	NLME_GET=NWKM;
	NLME_SET=NWKM;
	  
	  
}
