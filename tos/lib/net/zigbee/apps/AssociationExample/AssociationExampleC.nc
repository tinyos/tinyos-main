/*
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author Andre Cunha
 *
 */
#include <Timer.h>

#include "associationexample.h"
#include "phy_const.h"
#include "phy_enumerations.h"
#include "mac_const.h"
#include "mac_enumerations.h"
#include "mac_func.h"


configuration AssociationExampleC {
}
implementation {

  components MainC;
  components LedsC;
  components AssociationExampleP;
    
  AssociationExampleP.Boot -> MainC;
    
  components MacC;
  
  AssociationExampleP.Leds -> LedsC;
  
  components new TimerMilliC() as Timer0;
  AssociationExampleP.Timer0 -> Timer0;
   
  components new TimerMilliC() as Timer_Send;
  AssociationExampleP.Timer_Send ->Timer_Send;
   
   
  //MAC interfaces
  
  AssociationExampleP.MLME_START -> MacC.MLME_START;
  
  AssociationExampleP.MLME_GET ->MacC.MLME_GET;
  AssociationExampleP.MLME_SET ->MacC.MLME_SET;
  
  AssociationExampleP.MLME_BEACON_NOTIFY ->MacC.MLME_BEACON_NOTIFY;
  AssociationExampleP.MLME_GTS -> MacC.MLME_GTS;
  
  AssociationExampleP.MLME_ASSOCIATE->MacC.MLME_ASSOCIATE;
  AssociationExampleP.MLME_DISASSOCIATE->MacC.MLME_DISASSOCIATE;
  
  AssociationExampleP.MLME_ORPHAN->MacC.MLME_ORPHAN;
  AssociationExampleP.MLME_SYNC->MacC.MLME_SYNC;
  AssociationExampleP.MLME_SYNC_LOSS->MacC.MLME_SYNC_LOSS;
  AssociationExampleP.MLME_RESET->MacC.MLME_RESET;
  
  AssociationExampleP.MLME_SCAN->MacC.MLME_SCAN;
  
  
  AssociationExampleP.MCPS_DATA->MacC.MCPS_DATA;
  
  
}
