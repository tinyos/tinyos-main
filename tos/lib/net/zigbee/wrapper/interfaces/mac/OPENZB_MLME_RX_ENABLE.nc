/**
 * MLME-RX-ENABLE-Service Access Point
 *
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author IPP HURRAY http://www.open-zb.net
 * @author Ricardo Severino
 *
 *
 */

interface OPENZB_MLME_RX_ENABLE
{ 

  command result_t request(uint8_tDeferPermit, uint32_t RxOnTime, uint32_t RxOnDuration);
  
  event result_t confirm(uint8_t status);
  
  

}
