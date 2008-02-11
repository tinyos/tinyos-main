/**
 * MLME-POOL-Service Access Point
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author IPP HURRAY http://www.open-zb.net
 * @author Andre Cunha
 * pag 107
 */

interface MLME_POLL
{ 
  command result_t request(uint8_t CoordAddrMode, uint16_t CoorPANId, uint32_t CoorAddress[], uint8_t Security);
  
  event result_t confirm(uint8_t status);
  
}
