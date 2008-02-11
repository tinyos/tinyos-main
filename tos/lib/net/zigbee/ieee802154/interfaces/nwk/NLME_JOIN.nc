/**
 * NLME-JOIN
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author http://www.open-zb.net
 * @author Andre Cunha
 *
 *
 */
//page 173-179

interface NLME_JOIN
{ 

  
  command error_t request(uint16_t PANId, bool JoinAsRouter, bool RejoinNetwork, uint32_t ScanChannels, uint8_t ScanDuration, uint8_t PowerSource, uint8_t RxOnWhenIdle, uint8_t MACSecurity);
  
  event error_t indication(uint16_t ShortAddress, uint32_t ExtendedAddress[], uint8_t CapabilityInformation, bool SecureJoin);
  
  event error_t confirm(uint16_t PANId, uint8_t Status);
  
}
