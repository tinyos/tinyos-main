/**
 * MCPS-PURGE-Service Access Point
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author IPP HURRAY http://www.open-zb.net
 * @author Andre Cunha
 *
 *
 */

interface MCPS_PURGE
{ 
  command error_t request(uint8_t msduHandle);
    
  event error_t confirm(uint8_t msduHandle, uint8_t status);
  
}
