/*
 * MLME-COMM-STATUS-Service Access Point
 * std pag 96
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author IPP HURRAY http://www.open-zb.net
 * @author Andre Cunha
 *
 *
 */

interface MLME_COMM_STATUS
{ 

  event result_t indication(uint16_t PANId,uint8_t SrcAddrMode, uint32_t SrcAddr[], uint8_t DstAddrMode, uint32_t DstAddr[], uint8_t status);

}
