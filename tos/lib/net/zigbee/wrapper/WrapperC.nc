 /*
 * 
 * Wrapper layer to use the TKN 154 MAC
 * @author: Ricardo Severino <rars@isep.ipp.pt>
 * ========================================================================
 */ 

// move to a header file?
#define WRAPPER_MESSAGE_QUEUE_SIZE 5

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
  components WrapperP;

  WrapperP.MLME_RESET -> MAC;
  WrapperP.MLME_START -> MAC;
  
  WrapperP.MLME_GET -> MAC;
  WrapperP.MLME_SET -> MAC;
  
  WrapperP.MLME_BEACON_NOTIFY -> MAC;
  //WrapperP.MLME_GTS -> MAC;
  
  WrapperP.MLME_ASSOCIATE -> MAC;
  WrapperP.MLME_DISASSOCIATE -> MAC;
  
  WrapperP.MLME_ORPHAN -> MAC;
  WrapperP.MLME_SYNC -> MAC;
  WrapperP.MLME_SYNC_LOSS -> MAC;
  WrapperP.MLME_SCAN -> MAC;
    
  WrapperP.MCPS_DATA -> MAC;
  WrapperP.IEEE154Frame -> MAC;
  WrapperP.IEEE154BeaconFrame -> MAC;
  WrapperP.Packet -> MAC;

  components new PoolC(message_t, WRAPPER_MESSAGE_QUEUE_SIZE) as MessagePool;
  WrapperP.MessagePool -> MessagePool;


  OPENZB_MLME_RESET = WrapperP;
  OPENZB_MLME_START = WrapperP;

  OPENZB_MLME_GET = WrapperP;
  OPENZB_MLME_SET = WrapperP;

  OPENZB_MLME_BEACON_NOTIFY = WrapperP;
  OPENZB_MLME_GTS = WrapperP;

  OPENZB_MLME_ASSOCIATE = WrapperP;
  OPENZB_MLME_DISASSOCIATE = WrapperP;

  OPENZB_MLME_ORPHAN = WrapperP;
  OPENZB_MLME_SYNC = WrapperP;
  OPENZB_MLME_SYNC_LOSS = WrapperP;
  OPENZB_MLME_SCAN = WrapperP;

  OPENZB_MCPS_DATA = WrapperP;





}
