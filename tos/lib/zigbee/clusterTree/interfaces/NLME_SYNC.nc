/**
 * NLME-SYNC
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author http://www.open-zb.net
 * @author Andre Cunha
 *
 *
 */
//page 186-189

interface NLME_SYNC
{ 

  
  command error_t request(uint8_t Track);
  
  event error_t indication();
  
  event error_t confirm(uint8_t Status);
  
}
