/**
 * PD-Service Access Point
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author http://www.open-zb.net
 * @author Andre Cunha
 *
 *
 */
//#include <phy_enumerations.h>

interface PD_DATA
{ 
  async command error_t request(uint8_t psduLenght, uint8_t* psdu);
  
  async event error_t confirm(uint8_t status);
  
  async event error_t indication(uint8_t psduLenght,uint8_t* psdu, int8_t ppduLinkQuality);
 
}
