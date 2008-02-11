/**
 * NLME-RESET
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author http://www.open-zb.net
 * @author Andre Cunha
 *
 *
 */
//page 185-186

interface NLME_RESET
{ 

  
  command error_t request();
  
  event error_t confirm(uint8_t Status);
  
}
