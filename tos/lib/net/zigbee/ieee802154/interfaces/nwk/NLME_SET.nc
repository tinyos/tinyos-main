/**
 * NLME-SET
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author http://www.open-zb.net
 * @author Andre Cunha
 *
 *
 */
//page 191-192

interface NLME_SET
{ 

  command error_t request(uint8_t NIBAttribute, uint16_t NIBAttributeLength, uint16_t NIBAttributeValue);
  
  event error_t confirm(uint8_t Status, uint8_t NIBAttribute);
  
}
