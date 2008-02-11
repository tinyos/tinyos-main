/**
 * NLME-PERMIT_JOINING
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author http://www.open-zb.net
 * @author Andre Cunha
 *
 *
 */
//page 170-171

interface NLME_PERMIT_JOINING
{

  command error_t request(uint8_t PermitDuration);
    
  event error_t confirm(uint8_t Status);
  
}
