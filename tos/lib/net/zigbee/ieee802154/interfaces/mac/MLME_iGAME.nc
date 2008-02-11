/**
 * MLME-iGAME-Service Access Point
 *
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author IPP HURRAY http://www.open-zb.net
 * @author Andre Cunha
 *
 * A. Koubâa, M. Alves, E. Tovar " i-GAME: An Implicit GTS Allocation Mechanism in IEEE 802.15.4" 
 * Proceedings of the Euromicro Conference on Real-Time Systems (ECRTS 2006), July 2006.
 */

interface MLME_iGAME
{ 
  command result_t request(uint8_t GTSCharacteristics,uint16_t Flow_Specification, uint8_t SecurityEnable);
  
  command result_t response(Flow Flow_Description,uint8_t shared_time_slots, uint8_t status);
  
  event result_t confirm(uint8_t GTSCharacteristics,uint16_t Flow_Specification, uint8_t status);
  
  event result_t indication(uint16_t DevAddress, uint8_t GTSCharacteristics,uint16_t Flow_Specification, uint8_t SecurityUse, uint8_t ACLEntry);
}
