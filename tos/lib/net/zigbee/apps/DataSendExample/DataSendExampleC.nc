/**
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author Andre Cunha
 */
#include <Timer.h>

#include "datasendexample.h"
#include "phy_const.h"
#include "phy_enumerations.h"
#include "mac_const.h"
#include "mac_enumerations.h"
#include "mac_func.h"
 
configuration DataSendExampleC {
}
 
implementation
{
  components MainC;
  components LedsC;
  components DataSendExampleP;
    
  DataSendExampleP.Boot -> MainC;
    
  components MacC;
  
  DataSendExampleP.Leds -> LedsC;
  
  components new TimerMilliC() as Timer0;
  DataSendExampleP.Timer0 -> Timer0;
   
  components new TimerMilliC() as Timer_Send;
  DataSendExampleP.Timer_Send ->Timer_Send;
   
   
  //MAC interfaces
  
  DataSendExampleP.MLME_START -> MacC.MLME_START;
  
  DataSendExampleP.MLME_GET ->MacC.MLME_GET;
  DataSendExampleP.MLME_SET ->MacC.MLME_SET;
  
  DataSendExampleP.MLME_BEACON_NOTIFY ->MacC.MLME_BEACON_NOTIFY;
  DataSendExampleP.MLME_GTS -> MacC.MLME_GTS;
  
  DataSendExampleP.MLME_ASSOCIATE->MacC.MLME_ASSOCIATE;
  DataSendExampleP.MLME_DISASSOCIATE->MacC.MLME_DISASSOCIATE;
  
  DataSendExampleP.MLME_ORPHAN->MacC.MLME_ORPHAN;
  DataSendExampleP.MLME_SYNC->MacC.MLME_SYNC;
  DataSendExampleP.MLME_SYNC_LOSS->MacC.MLME_SYNC_LOSS;
  DataSendExampleP.MLME_RESET->MacC.MLME_RESET;
  
  DataSendExampleP.MLME_SCAN->MacC.MLME_SCAN;
  
  DataSendExampleP.MCPS_DATA->MacC.MCPS_DATA;

  
}

