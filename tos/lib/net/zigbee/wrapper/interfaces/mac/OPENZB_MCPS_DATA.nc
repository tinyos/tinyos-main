/**
 * MCPS-DATA-Service Access Point
 *
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author IPP HURRAY http://www.open-zb.net
 * @author Ricardo Severino
 *
 *
 */

interface OPENZB_MCPS_DATA
{ 
  command error_t request(uint8_t SrcAddrMode, uint16_t SrcPANId, uint32_t SrcAddr[], uint8_t DstAddrMode, uint16_t DestPANId, uint32_t DstAddr[], uint8_t msduLength, uint8_t msdu[],uint8_t msduHandle, uint8_t TxOptions);
  
  event error_t confirm(uint8_t msduHandle, uint8_t status);
																																								
  event error_t indication(uint16_t SrcAddrMode, uint16_t SrcPANId, uint32_t SrcAddr[2], uint16_t DstAddrMode, uint16_t DestPANId, uint32_t DstAddr[2], uint16_t msduLength,uint8_t msdu[100],uint16_t mpduLinkQuality, uint16_t SecurityUse, uint16_t ACLEntry);  

}
