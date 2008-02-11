/**
 * MLME-GET-Service Access Point
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author Andre Cunha
 *pag 78
 */

interface MLME_GET
{ 
  command error_t request(uint8_t PIBAttribute);
    
  event error_t confirm(uint8_t status,uint8_t PIBAttribute, uint8_t PIBAttributeValue[]);
  
}
