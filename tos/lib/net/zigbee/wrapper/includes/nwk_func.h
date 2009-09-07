/*
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author IPP HURRAY http://www.open-zb.net
 * @author Andre Cunha
 */

#ifndef __NWK_FUNC__
#define __NWK_FUNC__

//TEST
typedef struct associated_device
{

uint32_t address0;
uint32_t address1;

uint16_t pan_address;

}associated_device;
//END TEST

typedef struct routing_fields
{

//uint8_t frame_control1;
//uint8_t frame_control2;
uint16_t frame_control;
uint16_t destination_address;
uint16_t source_address;
uint8_t radius;
uint8_t sequence_number;

}routing_fields;

/*******************************************************************************************************************/  
/********************************NETWORK LAYER FRAME CONTROL FUNCTIONS************************************************************/
/*******************************************************************************************************************/
  
 //build NPDU frame control field
uint16_t set_route_frame_control(uint8_t Frame_type,uint8_t Protocol_version,uint8_t Discover_route,uint8_t Security) 
{
	  uint8_t fc_byte1=0;
	  uint8_t fc_byte2=0;
  	  fc_byte1 = ( (Discover_route << 6) | (Protocol_version << 2) | (Frame_type << 0) );				  
	  fc_byte2 = ((Security<< 2));
	  return ( (fc_byte2 <<8 ) | (fc_byte1 << 0) );

}


uint8_t route_fc1(uint8_t Security) 
{
	uint8_t fc;
	fc = ((Security << 2));
	return fc;
}

uint8_t route_fc2(uint8_t Frame_type,uint8_t Protocol_version,uint8_t Discover_route) 
{
	uint8_t fc;
	fc = ( (Discover_route << 6) | (Protocol_version << 2) | (Frame_type << 0) );	
	return fc;
}

uint8_t get_route_frame_type(uint16_t frame_control)
{
	return (frame_control & 0x3);
}

uint8_t get_route_protocol_version(uint16_t frame_control)
{
	return ( (frame_control >> 2) & 0xf);
}

uint8_t get_route_discover_route(uint16_t frame_control)
{
	return ( (frame_control >> 6) & 0x3);
}

uint8_t get_route_security(uint16_t frame_control)
{
	if( ((frame_control >> 8) & 0x2) == 0x2)
		return 1;
	else
		return 0;
}

/*******************************************************************************************************************/  
/********************************NETWORK LAYER BEACON PAYLOAD INFORMATION FUNCTIONS*********************************/
/*******************************************************************************************************************/

uint8_t nwk_payload_profile_protocolversion(uint8_t stackprofile,uint8_t nwkcprotocolversion)
{

return ((stackprofile << 0) | ( nwkcprotocolversion << 4));
}

uint8_t nwk_payload_capacity(uint8_t routercapacity,uint8_t devicedepth,uint8_t enddevicecapacity)
{

return ((enddevicecapacity << 7) | ( devicedepth << 3 ) | (routercapacity << 2 ) );
}


uint8_t get_protocolid(uint32_t nwk_information)
{
	return (uint8_t)((nwk_information & 0xFF000000) >> 24);
}

uint8_t get_stackprofile(uint32_t nwk_information)
{
	return (uint8_t)((nwk_information & 0x00F00000)>>20);
}

uint8_t get_nwkcprotocolversion(uint32_t nwk_information)
{
	return (uint8_t)((nwk_information & 0x000F0000)>>16);
}

uint8_t get_routercapacity(uint32_t nwk_information)
{
	if ( ( nwk_information & 0x00002000) == 0x00002000)
		return 1;
	else
		return 0;
}

uint8_t get_devicedepth(uint32_t nwk_information)
{
	return (uint8_t)((nwk_information & 0x00001F00) >> 8);
}

uint8_t get_enddevicecapacity(uint32_t nwk_information)
{
	if ( ( nwk_information & 0x00000001) == 0x00000001)
		return 1;
	else
		return 0;
}

#endif
