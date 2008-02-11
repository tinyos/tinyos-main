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


configuration AssociationExample {
}
implementation {

  components MainC;
  components LedsC;
  components AssociationExampleM;
    
  AssociationExampleM.Boot -> MainC;
    
  components Mac;
  
  AssociationExampleM.Leds -> LedsC;
  
  components new TimerMilliC() as Timer0;
  AssociationExampleM.Timer0 -> Timer0;
   
  components new TimerMilliC() as Timer_Send;
  AssociationExampleM.Timer_Send ->Timer_Send;
   
   
  //MAC interfaces
  
  AssociationExampleM.MLME_START -> Mac.MLME_START;
  
  AssociationExampleM.MLME_GET ->Mac.MLME_GET;
  AssociationExampleM.MLME_SET ->Mac.MLME_SET;
  
  AssociationExampleM.MLME_BEACON_NOTIFY ->Mac.MLME_BEACON_NOTIFY;
  AssociationExampleM.MLME_GTS -> Mac.MLME_GTS;
  
  AssociationExampleM.MLME_ASSOCIATE->Mac.MLME_ASSOCIATE;
  AssociationExampleM.MLME_DISASSOCIATE->Mac.MLME_DISASSOCIATE;
  
  AssociationExampleM.MLME_ORPHAN->Mac.MLME_ORPHAN;
  AssociationExampleM.MLME_SYNC->Mac.MLME_SYNC;
  AssociationExampleM.MLME_SYNC_LOSS->Mac.MLME_SYNC_LOSS;
  AssociationExampleM.MLME_RESET->Mac.MLME_RESET;
  
  AssociationExampleM.MLME_SCAN->Mac.MLME_SCAN;
  
  
  AssociationExampleM.MCPS_DATA->Mac.MCPS_DATA;
  
  
}
