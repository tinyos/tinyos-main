/**
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author Andre Cunha
 */
#include <Timer.h>

#include "simpleroutingexample.h"
#include "phy_const.h"
#include "phy_enumerations.h"
#include "mac_const.h"
#include "mac_enumerations.h"
#include "mac_func.h"

 configuration SimpleRoutingExample {
}
 
implementation
{
  components MainC;
  components LedsC;
  components SimpleRoutingExampleM;
    
  SimpleRoutingExampleM.Boot -> MainC;
    
  components Mac;
  
  SimpleRoutingExampleM.Leds -> LedsC;
  
  components new TimerMilliC() as Timer0;
  SimpleRoutingExampleM.Timer0 -> Timer0;
   
  components new TimerMilliC() as Timer_Send;
  SimpleRoutingExampleM.Timer_Send ->Timer_Send;
   
   
  //MAC interfaces
  
  SimpleRoutingExampleM.MLME_START -> Mac.MLME_START;
  
  SimpleRoutingExampleM.MLME_GET ->Mac.MLME_GET;
  SimpleRoutingExampleM.MLME_SET ->Mac.MLME_SET;
  
  SimpleRoutingExampleM.MLME_BEACON_NOTIFY ->Mac.MLME_BEACON_NOTIFY;
  SimpleRoutingExampleM.MLME_GTS -> Mac.MLME_GTS;
  
  SimpleRoutingExampleM.MLME_ASSOCIATE->Mac.MLME_ASSOCIATE;
  SimpleRoutingExampleM.MLME_DISASSOCIATE->Mac.MLME_DISASSOCIATE;
  
  SimpleRoutingExampleM.MLME_ORPHAN->Mac.MLME_ORPHAN;
  SimpleRoutingExampleM.MLME_SYNC->Mac.MLME_SYNC;
  SimpleRoutingExampleM.MLME_SYNC_LOSS->Mac.MLME_SYNC_LOSS;
  SimpleRoutingExampleM.MLME_RESET->Mac.MLME_RESET;
  
  SimpleRoutingExampleM.MLME_SCAN->Mac.MLME_SCAN;
  
  
  SimpleRoutingExampleM.MCPS_DATA->Mac.MCPS_DATA;

  
}

