/*
 * NLME-Network-Discovery
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author http://www.open-zb.net
 * @author Andre Cunha
 *
 *
 */
//page 164-167

interface NLME_NETWORK_DISCOVERY
{ 

  command error_t request(uint32_t ScanChannels, uint8_t ScanDuration);
  
  event error_t confirm(uint8_t NetworkCount,networkdescriptor networkdescriptorlist[], uint8_t Status);
  
}
