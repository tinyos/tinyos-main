/*
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author open-zb http://www.open-zb.net
 * @author Andre Cunha
 */


#ifndef __MAC_FUNC__
#define __MAC_FUNC__

/*******************************************************************************************************************/ 

uint8_t set_capability_information(uint8_t alternate_PAN_coordinator, uint8_t device_type, uint8_t power_source, uint8_t receiver_on_when_idle, uint8_t security, uint8_t allocate_address)
{
	
	return ((allocate_address << 7 ) | (security << 6 ) | (receiver_on_when_idle << 3 ) | (power_source << 2 ) | ( device_type << 1 ) | (alternate_PAN_coordinator << 0) );
}

uint8_t get_alternate_PAN_coordinator(uint8_t capability_information)
{

if ( (capability_information & 0x01) == 0x01)
	return 1;
else
	return 0;

}

  
/*******************************************************************************************************************/  
/********************************FRAME CONTROL FUNCTIONS************************************************************/
/*******************************************************************************************************************/
  
 //build MPDU frame control field
uint16_t set_frame_control(uint8_t frame_type,uint8_t security,uint8_t frame_pending,uint8_t ack_request,uint8_t intra_pan,uint8_t dest_addr_mode,uint8_t source_addr_mode) 
{
	  uint8_t fc_b1=0;
	  uint8_t fc_b2=0;
  	  fc_b1 = ( (intra_pan << 6) | (ack_request << 5) | (frame_pending << 4) |
 	   		  (security << 3) | (frame_type << 0) );				  
	  fc_b2 = ( (source_addr_mode << 6) | (dest_addr_mode << 2));
	  return ( (fc_b2 << 8 ) | (fc_b1 << 0) );

} 


//return the type of destination address specified in the frame control 

uint8_t get_fc2_dest_addr(uint8_t frame_control)
{
	switch( frame_control & 0xC )
	{
	case 0x4:	return RESERVED_ADDRESS; 
							break;
	case 0x8: return SHORT_ADDRESS;
						 break;
	case 0xC: return LONG_ADDRESS;
						break;
	default:
			return 0; 
			break;
	}
}


//return the type of source address specified in the frame control 

uint8_t get_fc2_source_addr(uint8_t frame_control)
{
	switch(frame_control & 0xC0 )
	{
	case 0x40:	return RESERVED_ADDRESS; 
							break;
	case 0x80: return SHORT_ADDRESS;
						 break;
	case 0xC0: return LONG_ADDRESS;
						break;
	default:
			return 0; 
			break;
	}
}



bool get_fc1_security(uint8_t frame_control)
{

if ( (frame_control & 0x8) == 0x8)
	return 1;
else
	return 0;

}

bool get_fc1_frame_pending(uint8_t frame_control)
{

if ( (frame_control & 0x10) == 0x10)
	return 1;
else
	return 0;
	
}

bool get_fc1_ack_request(uint8_t frame_control)
{

if ( (frame_control & 0x20) == 0x20)
	return 1;
else
	return 0;
	
}

bool get_fc1_intra_pan(uint8_t frame_control)
{

if ( (frame_control & 0x40) == 0x40)
	return 1;
else
	return 0;
	
} 
 
  
/*******************************************************************************************************************/  
/********************************SUPERFRAME SPECIFICATION FUNCTIONS*************************************************/
/*******************************************************************************************************************/

//build beacon superframe specification
uint16_t set_superframe_specification(uint8_t beacon_order,uint8_t superframe_order,uint8_t final_cap_slot,uint8_t battery_life_extension,uint8_t pan_coordinator,uint8_t association_permit)
{
	  uint8_t sf_b1=0;
	  uint8_t sf_b2=0;
	  sf_b1 = ( (superframe_order << 4) | (beacon_order <<0));
	  sf_b2 = ( (association_permit << 7) | (pan_coordinator << 6) |
	  		    (battery_life_extension << 4) | (final_cap_slot << 0) );
	   return  ( (sf_b2 <<8 ) | (sf_b1 << 0) );  
   
}

uint8_t get_beacon_order(uint16_t superframe)
{
	return ((uint8_t)superframe &  0xF);
}

uint8_t get_superframe_order(uint16_t superframe)
{
	return (((uint8_t)superframe >> 4) &  0xF);
}



bool get_pan_coordinator(uint16_t superframe)
{
if ( ((uint8_t)superframe & 0x40) == 0x40)
	return 1;
else
	return 0;
	
}

bool get_association_permit(uint16_t superframe)
{
if ( ((uint8_t)superframe & 0x80) == 0x80)
	return 1;
else
	return 0;	
}

bool get_battery_life_extention(uint16_t superframe)
{
if ( ((uint8_t)superframe & 0x10) == 0x10)
	return 1;
else
	return 0;	
}

uint8_t get_final_cap_slot(uint16_t superframe)
{
return (((uint8_t)superframe >> 4) &  0xF);
}


/*******************************************************************************************************************/  
/********************************      DATA TX OPTIONS   ************************************************************/
/*******************************************************************************************************************/
  
  
uint8_t set_txoptions(uint8_t ack, uint8_t gts, uint8_t indirect_transmission,uint8_t security)
{
return ( (ack << 0) | (gts << 1) | (indirect_transmission << 2) | (security << 3 ) );
}  
  
bool get_txoptions_ack(uint8_t txoptions)
{

if ( (txoptions & 0x1) == 0x1)
	return 1;
else
	return 0;

}
  
bool get_txoptions_gts(uint8_t txoptions)
{

if ( (txoptions & 0x2) == 0x2)
	return 1;
else
	return 0;

}  

bool get_txoptions_indirect_transmission(uint8_t txoptions)
{

if ( (txoptions & 0x4) == 0x4)
	return 1;
else
	return 0;

}  

bool get_txoptions_security(uint8_t txoptions)
{

if ( (txoptions & 0x8) == 0x8)
	return 1;
else
	return 0;
}


//BEACON SCHEDULING IMPLEMENTATION
bool get_txoptions_upstream_buffer(uint8_t txoptions) 
{

if ( (txoptions & 0x10) == 0x10)
	return 1;
else
	return 0;
}

uint8_t set_txoptions_upstream(uint8_t ack, uint8_t gts, uint8_t indirect_transmission,uint8_t security,uint8_t upstream)
{
return ( (ack << 0) | (gts << 1) | (indirect_transmission << 2) | (security << 3 ) | (upstream << 4) );
} 


/*******************************************************************************************************************/  
/********************************PENDING ADDRESSES FUNCTIONS********************************************************/
/*******************************************************************************************************************/
uint8_t set_pending_address_specification(uint8_t number_short, uint8_t number_extended)
{
	return ( (number_extended << 4) | (number_short << 0) );
}

uint8_t get_number_short(uint8_t pending_specification)
{
	return (pending_specification & 0x07);
}

uint8_t get_number_extended(uint8_t pending_specification)
{
	return ( (pending_specification >> 4) & 0x07);
}


/*******************************************************************************************************************/  
/********************************GTS FIELDS FUNCTIONS***************************************************************/
/*******************************************************************************************************************/
uint8_t set_gts_specification(uint8_t gts_descriptor_count, uint8_t gts_permit)
{
	return ( ( gts_descriptor_count << 0) | (gts_permit << 7) );  
}

uint8_t get_gts_permit(uint8_t gts_specification)
{
return ( (gts_specification >> 7) & 0x01);
}


///UNUSED
uint8_t set_gts_directions(uint8_t gts1,uint8_t gts2,uint8_t gts3,uint8_t gts4,uint8_t gts5,uint8_t gts6,uint8_t gts7)
{
	return ((gts1 << 0) | (0 << 7));
}


uint8_t set_gts_descriptor(uint8_t GTS_starting_slot, uint8_t GTS_length)
{
//part of the descriptor list
	return ( (GTS_starting_slot << 0) | (GTS_length << 4) );
}

uint8_t get_gts_descriptor_len(uint8_t gts_des_part)
{
	return ( (gts_des_part & 0xf0) >> 4);
}

uint8_t get_gts_descriptor_ss(uint8_t gts_des_part)
{
	return (gts_des_part & 0x0f);
}



/************************************************************************************************/  
/********************************GTS CHARACTERISTICS*************************************************/
/************************************************************************************************/
uint8_t set_gts_characteristics(uint8_t gts_length, uint8_t gts_direction, uint8_t characteristic_type)
{
	return ( (gts_length << 0) | (gts_direction << 4) | (characteristic_type << 5));
}  
 
 
uint8_t get_gts_length(uint8_t gts_characteristics)
{
	return (gts_characteristics &  0xF);
}

bool get_gts_direction(uint8_t gts_characteristics)
{
	if ( (gts_characteristics & 0x10) == 0x10)
		return 1;
	else
		return 0;
}  

uint8_t get_characteristic_type(uint8_t gts_characteristics)
{
	if ( (gts_characteristics & 0x20) == 0x20)
		return 1;
	else
		return 0;
} 


/************************************************************************************************/  
/********************************OTHER FUNCTIONS*************************************************/
/************************************************************************************************/
  /* A Task to calculate CRC for message transmission */
  /*
  task void CRCCalc() {
    uint16_t length = txLength;
    uint16_t crc = calcrc(sendPtr, length - 2);
    
    sendPtr[length - 2] = crc & 0xff;
    sendPtr[length - 1] = (crc >> 8) & 0xff;
    
  }
  */
  
uint16_t get_crcByte(uint16_t crc, uint8_t b)
{
  uint8_t i;
  
  crc = crc ^ b << 8;
  i = 8;
  do
    if (crc & 0x8000)
      crc = crc << 1 ^ 0x1021;
    else
      crc = crc << 1;
  while (--i);

  return crc;
}
  /* Internal function to calculate 16 bit CRC */
  uint16_t calcrc(uint8_t *ptr, uint8_t count) {
    uint16_t crc;
    //uint8_t i;
  
    crc = 0;
    while (count-- > 0)
      crc = get_crcByte(crc, *ptr++);

    return crc;
  }

#endif

