/**
 * NLME-DIRECT-JOIN
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author http://www.open-zb.net
 * @author Andre Cunha
 */
//page 179-181

interface NLME_DIRECT_JOIN
{ 

  
  command error_t request(uint32_t DeviceAddress0, uint32_t DeviceAddress1, CapabilityInformation);
  
  event error_t confirm(uint32_t DeviceAddress0,uint32_t DeviceAddress1, uint8_t Status);
  
}
