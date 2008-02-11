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
 
configuration DataSendExample {
}
 
implementation
{
  components MainC;
  components LedsC;
  components DataSendExampleM;
    
  DataSendExampleM.Boot -> MainC;
    
  components Mac;
  
  DataSendExampleM.Leds -> LedsC;
  
  components new TimerMilliC() as Timer0;
  DataSendExampleM.Timer0 -> Timer0;
   
  components new TimerMilliC() as Timer_Send;
  DataSendExampleM.Timer_Send ->Timer_Send;
   
   
  //MAC interfaces
  
  DataSendExampleM.MLME_START -> Mac.MLME_START;
  
  DataSendExampleM.MLME_GET ->Mac.MLME_GET;
  DataSendExampleM.MLME_SET ->Mac.MLME_SET;
  
  DataSendExampleM.MLME_BEACON_NOTIFY ->Mac.MLME_BEACON_NOTIFY;
  DataSendExampleM.MLME_GTS -> Mac.MLME_GTS;
  
  DataSendExampleM.MLME_ASSOCIATE->Mac.MLME_ASSOCIATE;
  DataSendExampleM.MLME_DISASSOCIATE->Mac.MLME_DISASSOCIATE;
  
  DataSendExampleM.MLME_ORPHAN->Mac.MLME_ORPHAN;
  DataSendExampleM.MLME_SYNC->Mac.MLME_SYNC;
  DataSendExampleM.MLME_SYNC_LOSS->Mac.MLME_SYNC_LOSS;
  DataSendExampleM.MLME_RESET->Mac.MLME_RESET;
  
  DataSendExampleM.MLME_SCAN->Mac.MLME_SCAN;
  
  DataSendExampleM.MCPS_DATA->Mac.MCPS_DATA;

  
}

