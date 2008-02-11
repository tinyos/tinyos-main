/**
 * MLME-DISASSOCIATE-Service Access Point
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author IPP HURRAY http://www.open-zb.net
 * @author Andre Cunha
 * pag 73
 *
 */

interface MLME_DISASSOCIATE
{ 
  command error_t request(uint32_t DeviceAddress[], uint8_t DisassociateReason, uint8_t SecurityEnable);
  
  event error_t indication(uint32_t DeviceAddress[], uint8_t DisassociateReason, uint8_t SecurityUse, uint8_t ACLEntry);
  
  event error_t confirm(uint8_t status);
  
}
