/**
 * NLME-LEAVE
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author http://www.open-zb.net
 * @author Andre Cunha
 *
 *
 */
//page 181-184

interface NLME_LEAVE
{

  
  command error_t request(uint64_t extDeviceAddress, uint8_t RemoveChildren, uint8_t MACSecurityEnable);
  
  event error_t indication(uint64_t extDeviceAddress);
  
  event error_t confirm(uint64_t extDeviceAddress, uint8_t status);
  
}
