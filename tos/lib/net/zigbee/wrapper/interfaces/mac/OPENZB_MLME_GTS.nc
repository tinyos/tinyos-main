/**
 * MLME-GTS-Service Access Point
 *
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author IPP HURRAY http://www.open-zb.net
 * @author Ricardo Severino
 *
 *
 */
interface OPENZB_MLME_GTS
{ 
  command error_t request(uint8_t GTSCharacteristics, uint8_t SecurityEnable);
  
  event error_t confirm(uint8_t GTSCharacteristics, uint8_t status);
  
  event error_t indication(uint16_t DevAddress, uint8_t GTSCharacteristics, uint8_t SecurityUse, uint8_t ACLEntry);
}
