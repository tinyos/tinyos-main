/**
 * MLME-SET-Service Access Point
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author IPP HURRAY http://www.open-zb.net
 * @author Andre Cunha
 * pag 98
 */

interface MLME_SET
{ 
  command error_t request(uint8_t PIBAttribute,uint8_t PIBAttributeValue[]);

  event error_t confirm(uint8_t status,uint8_t PIBAttribute);

}
