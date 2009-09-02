/**
 * MLME-ASSOCIATE-Service Access Point
 *	std pag 65
 *
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author IPP HURRAY http://www.open-zb.net
 * @author Ricardo Severino
 *
 *
 */

interface OPENZB_MLME_ASSOCIATE
{ 
  command error_t request(uint8_t LogicalChannel,uint8_t CoordAddrMode,uint16_t CoordPANId,uint32_t CoordAddress[],uint8_t CapabilityInformation,bool SecurityEnable);
  
  event error_t indication(uint32_t DeviceAddress[], uint8_t CapabilityInformation, bool SecurityUse, uint8_t ACLEntry);
  
  command error_t response(uint32_t DeviceAddress[], uint16_t AssocShortAddress, uint8_t status, bool SecurityEnable);
  
  event error_t confirm(uint16_t AssocShortAddress, uint8_t status);
  
}
