/**
 * NLDE-DATA
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author open-zb http://www.open-zb.net
 * @author Andre Cunha
 *
 */
//page 159-163

interface NLDE_DATA
{ 

  command error_t request(uint16_t DstAddr, uint16_t NsduLength, uint8_t Nsdu[100], uint8_t NsduHandle, uint8_t Radius, uint8_t DiscoverRoute, uint8_t SecurityEnable);
  
  event error_t indication(uint16_t SrcAddress, uint16_t NsduLength,uint8_t Nsdu[100], uint16_t LinkQuality);
  
  event error_t confirm(uint8_t NsduHandle, uint8_t Status);
  
}
