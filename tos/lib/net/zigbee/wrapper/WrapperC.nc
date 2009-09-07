 /*
 * 
 * 
 * @author: Ricardo Severino <rars@isep.ipp.pt>
 * ========================================================================
 */ 


configuration WrapperC
{
  provides
  {
    interface OPENZB_MLME_RESET;
    interface OPENZB_MLME_START;
  
    interface OPENZB_MLME_GET;
    interface OPENZB_MLME_SET;
  
    interface OPENZB_MLME_BEACON_NOTIFY;
    interface OPENZB_MLME_GTS;
  
    interface OPENZB_MLME_ASSOCIATE;
    interface OPENZB_MLME_DISASSOCIATE;
  
    interface OPENZB_MLME_ORPHAN;
    interface OPENZB_MLME_SYNC;
    interface OPENZB_MLME_SYNC_LOSS;
    interface OPENZB_MLME_SCAN;
    
    interface OPENZB_MCPS_DATA;


  }

}

implementation
{

  components Ieee802154BeaconEnabledC as MAC; 
  components WrapperM;

  WrapperM.MLME_RESET -> MAC;
  WrapperM.MLME_START -> MAC;
  
  WrapperM.MLME_GET -> MAC;
  WrapperM.MLME_SET -> MAC;
  
  WrapperM.MLME_BEACON_NOTIFY -> MAC;
  WrapperM.MLME_GTS -> MAC;
  
  WrapperM.MLME_ASSOCIATE -> MAC;
  WrapperM.MLME_DISASSOCIATE -> MAC;
  
  WrapperM.MLME_ORPHAN -> MAC;
  WrapperM.MLME_SYNC -> MAC;
  WrapperM.MLME_SYNC_LOSS -> MAC;
  WrapperM.MLME_SCAN -> MAC;
    
  WrapperM.MCPS_DATA -> MAC;




  OPENZB_MLME_RESET = WrapperM;
  OPENZB_MLME_START = WrapperM;

  OPENZB_MLME_GET = WrapperM;
  OPENZB_MLME_SET = WrapperM;

  OPENZB_MLME_BEACON_NOTIFY = WrapperM;
  OPENZB_MLME_GTS = WrapperM;

  OPENZB_MLME_ASSOCIATE = WrapperM;
  OPENZB_MLME_DISASSOCIATE = WrapperM;

  OPENZB_MLME_ORPHAN = WrapperM;
  OPENZB_MLME_SYNC = WrapperM;
  OPENZB_MLME_SYNC_LOSS = WrapperM;
  OPENZB_MLME_SCAN = WrapperM;

  OPENZB_MCPS_DATA = WrapperM;





}