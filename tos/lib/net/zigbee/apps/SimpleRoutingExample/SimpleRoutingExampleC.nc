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

 configuration SimpleRoutingExampleC {
}
 
implementation
{
  components MainC;
  components LedsC;
  components SimpleRoutingExampleP;
    
  SimpleRoutingExampleP.Boot -> MainC;
    
  components MacC;
  
  SimpleRoutingExampleP.Leds -> LedsC;
  
  components new TimerMilliC() as Timer0;
  SimpleRoutingExampleP.Timer0 -> Timer0;
   
  components new TimerMilliC() as Timer_Send;
  SimpleRoutingExampleP.Timer_Send ->Timer_Send;
   
   
  //MAC interfaces
  
  SimpleRoutingExampleP.MLME_START -> MacC.MLME_START;
  
  SimpleRoutingExampleP.MLME_GET ->MacC.MLME_GET;
  SimpleRoutingExampleP.MLME_SET ->MacC.MLME_SET;
  
  SimpleRoutingExampleP.MLME_BEACON_NOTIFY ->MacC.MLME_BEACON_NOTIFY;
  SimpleRoutingExampleP.MLME_GTS -> MacC.MLME_GTS;
  
  SimpleRoutingExampleP.MLME_ASSOCIATE->MacC.MLME_ASSOCIATE;
  SimpleRoutingExampleP.MLME_DISASSOCIATE->MacC.MLME_DISASSOCIATE;
  
  SimpleRoutingExampleP.MLME_ORPHAN->MacC.MLME_ORPHAN;
  SimpleRoutingExampleP.MLME_SYNC->MacC.MLME_SYNC;
  SimpleRoutingExampleP.MLME_SYNC_LOSS->MacC.MLME_SYNC_LOSS;
  SimpleRoutingExampleP.MLME_RESET->MacC.MLME_RESET;
  
  SimpleRoutingExampleP.MLME_SCAN->MacC.MLME_SCAN;
  
  
  SimpleRoutingExampleP.MCPS_DATA->MacC.MCPS_DATA;

  
}

