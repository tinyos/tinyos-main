/**
 * MLME-RESET-Service Access Point
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author IPP HURRAY http://www.open-zb.net
 * @author Andre Cunha
 *
 *
 */

interface MLME_RESET
{ 

  command error_t request(uint8_t set_default_PIB);
  
  event error_t confirm(uint8_t status);
  
  

}
