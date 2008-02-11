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


configuration GTSManagementExample {
}
implementation {

  components MainC;
  components LedsC;
  components GTSManagementExampleM;
    
  GTSManagementExampleM.Boot -> MainC;
    
  components Mac;
  
  GTSManagementExampleM.Leds -> LedsC;
  
  components new TimerMilliC() as Timer0;
  GTSManagementExampleM.Timer0 -> Timer0;
   
  components new TimerMilliC() as Timer_Send;
  GTSManagementExampleM.Timer_Send ->Timer_Send;
   
   
  //MAC interfaces
  
  GTSManagementExampleM.MLME_START -> Mac.MLME_START;
  
  GTSManagementExampleM.MLME_GET ->Mac.MLME_GET;
  GTSManagementExampleM.MLME_SET ->Mac.MLME_SET;
  
  GTSManagementExampleM.MLME_BEACON_NOTIFY ->Mac.MLME_BEACON_NOTIFY;
  GTSManagementExampleM.MLME_GTS -> Mac.MLME_GTS;
  
  GTSManagementExampleM.MLME_ASSOCIATE->Mac.MLME_ASSOCIATE;
  GTSManagementExampleM.MLME_DISASSOCIATE->Mac.MLME_DISASSOCIATE;
  
  GTSManagementExampleM.MLME_ORPHAN->Mac.MLME_ORPHAN;
  GTSManagementExampleM.MLME_SYNC->Mac.MLME_SYNC;
  GTSManagementExampleM.MLME_SYNC_LOSS->Mac.MLME_SYNC_LOSS;
  GTSManagementExampleM.MLME_RESET->Mac.MLME_RESET;
  
  GTSManagementExampleM.MLME_SCAN->Mac.MLME_SCAN;
  
  
  GTSManagementExampleM.MCPS_DATA->Mac.MCPS_DATA;
  
  
}

