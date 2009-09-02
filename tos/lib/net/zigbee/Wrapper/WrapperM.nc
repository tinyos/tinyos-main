 
module WrapperM
{
  uses {
    interface MLME_START;
    interface MLME_SET;
    interface MLME_GET;
    
    interface MLME_ASSOCIATE;
    interface MLME_DISASSOCIATE;
    
    interface MLME_BEACON_NOTIFY;
    interface MLME_GTS;
    
    interface MLME_ORPHAN;

    interface MLME_SYNC;
    interface MLME_SYNC_LOSS;
    
    interface MLME_RESET;
    
    interface MLME_SCAN;
    
    //MCPS
    interface MCPS_DATA;
    interface MCPS_PURGE;
  }

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

/******************************************************************
 ***************	TKN154 INTERFACES	*******************
******************************************************************/

  event void MLME_RESET.confirm(ieee154_status_t status)
  {
  
  
  }


  event void MLME_ASSOCIATE.indication (
                          uint64_t DeviceAddress,
                          ieee154_CapabilityInformation_t CapabilityInformation,
                          ieee154_security_t *security
                        )
  {
  }

  event void MLME_ASSOCIATE.confirm    (
                          uint16_t AssocShortAddress,
                          uint8_t status,
                          ieee154_security_t *security
                        )
  {
  }

 
  event void MLME_DISASSOCIATE.indication (
                          uint64_t DeviceAddress,
                          ieee154_disassociation_reason_t DisassociateReason,
                          ieee154_security_t *security
                        )
  {
  }


  event void MLME_DISASSOCIATE.confirm    (
                          ieee154_status_t status,
                          uint8_t DeviceAddrMode,
                          uint16_t DevicePANID,
                          ieee154_address_t DeviceAddress
                        )
  {
  }

 event void MLME_START.confirm    (
                          ieee154_status_t status
                        )

  {
  }


  event void MLME_SCAN.confirm    (
                          ieee154_status_t status,
                          uint8_t ScanType,
                          uint8_t ChannelPage,
                          uint32_t UnscannedChannels,
                          uint8_t EnergyDetectNumResults,
                          int8_t* EnergyDetectList,
                          uint8_t PANDescriptorListNumResults,
                          ieee154_PANDescriptor_t* PANDescriptorList
                        )

  {
  }


  event message_t* MLME_BEACON_NOTIFY.indication ( message_t *beaconFrame )

  {
  }



  event void MLME_ORPHAN.indication (
                          uint64_t OrphanAddress,
                          ieee154_security_t *security
                        )

  {
  }


  event void MLME_SYNC_LOSS.indication (
                          ieee154_status_t lossReason,
                          uint16_t PANId,
                          uint8_t LogicalChannel,
                          uint8_t ChannelPage,
                          ieee154_security_t *security
                        )
  {
  }


  event void MLME_GTS.confirm    (
                          uint8_t GtsCharacteristics,
                          ieee154_status_t status
                        )
  {
  }


  event void MLME_GTS.indication (
                          uint16_t DeviceAddress,
                          uint8_t GtsCharacteristics,
                          ieee154_security_t *security
                        )
  {
  }


  event void MCPS_DATA.confirm    (  
                          message_t *frame,
                          uint8_t msduHandle,
                          ieee154_status_t status,
                          uint32_t Timestamp
                        )
  {
  }

  event message_t* MCPS_DATA.indication ( message_t* frame )
  {
  }




/******************************************************************
 ***************	OPEN-ZB INTERFACES	*******************
******************************************************************/

  command error_t OPENZB_MLME_RESET.request(uint8_t set_default_PIB)
  {
    printfUART("MLME_RESET.request\n", "");

    return SUCCESS;
  }

  


  command error_t OPENZB_MLME_START.request(uint32_t PANId, uint8_t LogicalChannel, uint8_t beacon_order, uint8_t superframe_order,bool pan_coodinator,bool BatteryLifeExtension,bool CoordRealignment,bool securityenable,uint32_t StartTime)
  {
  }



  command error_t OPENZB_MLME_SYNC.request(uint8_t logical_channel,uint8_t track_beacon)
  {
	  

  return SUCCESS;
  }

  command error_t OPENZB_MLME_SET.request(uint8_t PIBAttribute,uint8_t PIBAttributeValue[])
  {
  }

  command error_t OPENZB_MLME_GET.request(uint8_t PIBAttribute)
  {
  }

  command error_t OPENZB_MLME_SCAN.request(uint8_t ScanType, uint32_t ScanChannels, uint8_t ScanDuration)
  {
  //pag 93
  }


  command error_t OPENZB_MLME_ORPHAN.response(uint32_t OrphanAddress[1],uint16_t ShortAddress,uint8_t AssociatedMember, uint8_t security_enabled)
  {
  }


  command error_t OPENZB_MCPS_DATA.request(uint8_t SrcAddrMode, uint16_t SrcPANId, uint32_t SrcAddr[], uint8_t DstAddrMode, uint16_t DestPANId, uint32_t DstAddr[], uint8_t msduLength, uint8_t msdu[],uint8_t msduHandle, uint8_t TxOptions)
  {
  }

  command error_t OPENZB_MLME_ASSOCIATE.request(uint8_t LogicalChannel,uint8_t CoordAddrMode,uint16_t CoordPANId,uint32_t CoordAddress[],uint8_t CapabilityInformation,bool securityenable)
  {
  }

  command error_t OPENZB_MLME_ASSOCIATE.response(uint32_t DeviceAddress[], uint16_t AssocShortAddress, uint8_t status, bool securityenable)
  {
  }
  command error_t OPENZB_MLME_DISASSOCIATE.request(uint32_t DeviceAddress[], uint8_t disassociate_reason, bool securityenable)
  {
  }

  command error_t OPENZB_MLME_GTS.request(uint8_t GTSCharacteristics, bool security_enable)
  {
  }


}




