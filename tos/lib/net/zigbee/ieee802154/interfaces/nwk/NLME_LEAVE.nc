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

  
  command error_t request(uint32_t DeviceAddress[],uint8_t RemoveChildren, uint8_t MACSecurityEnable);
  
  event error_t indication(uint32_t DeviceAddress[]);
  
  event error_t confirm(uint32_t DeviceAddress[], uint8_t Status);
  
}
