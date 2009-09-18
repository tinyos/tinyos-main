/**
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author Andre Cunha
 */
#include <Timer.h>

#include "gtsmanagementexample.h"
#include "phy_const.h"
#include "phy_enumerations.h"
#include "mac_const.h"
#include "mac_enumerations.h"
#include "mac_func.h"


configuration GTSManagementExampleC {
}
implementation {

  components MainC;
  components LedsC;
  components GTSManagementExampleP;
    
  GTSManagementExampleP.Boot -> MainC;
    
  components MacC;
  
  GTSManagementExampleP.Leds -> LedsC;
  
  components new TimerMilliC() as Timer0;
  GTSManagementExampleP.Timer0 -> Timer0;
   
  components new TimerMilliC() as Timer_Send;
  GTSManagementExampleP.Timer_Send ->Timer_Send;
   
   
  //MAC interfaces
  
  GTSManagementExampleP.MLME_START -> MacC.MLME_START;
  
  GTSManagementExampleP.MLME_GET ->MacC.MLME_GET;
  GTSManagementExampleP.MLME_SET ->MacC.MLME_SET;
  
  GTSManagementExampleP.MLME_BEACON_NOTIFY ->MacC.MLME_BEACON_NOTIFY;
  GTSManagementExampleP.MLME_GTS -> MacC.MLME_GTS;
  
  GTSManagementExampleP.MLME_ASSOCIATE->MacC.MLME_ASSOCIATE;
  GTSManagementExampleP.MLME_DISASSOCIATE->MacC.MLME_DISASSOCIATE;
  
  GTSManagementExampleP.MLME_ORPHAN->MacC.MLME_ORPHAN;
  GTSManagementExampleP.MLME_SYNC->MacC.MLME_SYNC;
  GTSManagementExampleP.MLME_SYNC_LOSS->MacC.MLME_SYNC_LOSS;
  GTSManagementExampleP.MLME_RESET->MacC.MLME_RESET;
  
  GTSManagementExampleP.MLME_SCAN->MacC.MLME_SCAN;
  
  
  GTSManagementExampleP.MCPS_DATA->MacC.MCPS_DATA;
  
  
}

