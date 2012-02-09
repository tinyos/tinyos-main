/*
 * NLME-NETWORK-FORMATION
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author http://www.open-zb.net
 * @author Andre Cunha
 *
 *
 */
//page 167-169

interface NLME_NETWORK_FORMATION
{ 

  command error_t request(uint8_t logicalChannel, uint8_t ScanDuration, uint8_t BeaconOrder, uint8_t SuperframeOrder, uint16_t PANId, bool BatteryLifeExtension);
  //command error_t request(uint32_t ScanChannels, uint8_t ScanDuration, uint8_t BeaconOrder, uint8_t SuperframeOrder, uint16_t PANId, uint8_t BatteryLifeExtension);
  
  event error_t confirm(uint8_t Status);
  
}
