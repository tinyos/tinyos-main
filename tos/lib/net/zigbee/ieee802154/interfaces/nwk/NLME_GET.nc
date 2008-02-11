/**
 * NLME-GET
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author http://www.open-zb.net
 * @author Andre Cunha
 *
 *
 */
//page 190-191

interface NLME_GET
{ 

  command error_t request(uint8_t NIBAttribute);
  
  event error_t confirm(uint8_t Status, uint8_t NIBAttribute, uint16_t NIBAttributeLength, uint16_t NIBAttributeValue);
  
}
