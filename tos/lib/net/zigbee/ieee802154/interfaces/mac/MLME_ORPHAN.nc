/**
 * MLME-ORPHAN-Service Access Point
 *
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author IPP HURRAY http://www.open-zb.net
 * @author Andre Cunha
 *
 */

interface MLME_ORPHAN
{ 

  event error_t indication(uint32_t OrphanAddress[1], uint8_t SecurityUse, uint8_t ACLEntry);
  
  command error_t response(uint32_t OrphanAddress[1],uint16_t ShortAddress,uint8_t AssociatedMember, uint8_t security_enabled);

}
