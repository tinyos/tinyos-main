/**
 *
 * @author André Cunha 
 * @version 1.0
 */

interface AddressFilter {


   command error_t set_address(uint16_t mac_short_address, uint32_t mac_extended0, uint32_t mac_extended1);
      
	  
   command error_t set_coord_address(uint16_t mac_coord_address, uint16_t mac_panid);
   
   
   command error_t enable_address_decode(uint8_t enable);


}

