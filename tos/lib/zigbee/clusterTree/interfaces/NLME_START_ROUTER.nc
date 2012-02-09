/**
 * NLME-Start-Router
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author http://www.open-zb.net
 * @author Andre Cunha
 *
 */
//page 171-173

interface NLME_START_ROUTER
{ 

  command error_t request(uint8_t BeaconOrder, uint8_t SuperframeOrder, uint8_t BatteryLifeExtension,uint32_t StartTime);
  
  event error_t confirm(uint8_t Status);
  
}
