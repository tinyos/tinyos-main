/*
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author open-zb http://www.open-zb.net
 * @author Andre Cunha
 */

//MAC frame Superstructure

#ifndef __FRAME_FORMAT__
#define __FRAME_FORMAT__


#define MPDU_HEADER_LEN 5

typedef struct MPDU
{
	uint8_t length;
	//info on frame type/ack/etc
	uint8_t frame_control1;
	//info on addressing fields
	uint8_t frame_control2;
	//uint16_t frame_control;
	uint8_t seq_num;
	uint8_t data[120];
}MPDU;

typedef struct MPDUBuffer
{
	uint8_t length;
	//uint16_t frame_control;
	uint8_t frame_control1;
	uint8_t frame_control2;
	uint8_t seq_num;
	uint8_t data[120];
	uint8_t retransmission;
	uint8_t indirect;
}MPDUBuffer;

//PD_DATA validation structures



/*****************************************************/
/*				BEACON FRAME SCTRUCTURES			 */
/*****************************************************/

//#define beacon_addr_short_length 7
//#define beacon_addr_long_length 12


typedef struct beacon_addr_short
{
	uint16_t destination_PAN_identifier;
	uint16_t destination_address;
	uint16_t source_address;
	uint16_t superframe_specification;
}beacon_addr_short;
/*
typedef struct beacon_struct
{
	uint8_t length;
	uint16_t frame_control;
	uint8_t seq_num;
	uint16_t source_PAN_identifier;
	uint16_t destination_address;
	uint16_t source_address;
	uint16_t superframe_specification;
}beacon_struct;
*/
/*
typedef struct beacon_addr_long
{
	uint16_t source_PAN_identifier;
	uint32_t source_address0;
	uint32_t source_address1;
	uint16_t superframe_specification;
}beacon_addr_long;
*/
/*****************************************************/
/*				ACK FRAME Structures 				 */
/*****************************************************/

typedef struct ACK
{
	uint8_t length;
	uint8_t frame_control1;
	uint8_t frame_control2;
	//uint16_t frame_control;
	uint8_t seq_num;
}ACK;

/*****************************************************/
/*				COMMAND FRAME Structures 			 */
/*****************************************************/

typedef struct cmd_association_request
{
	uint8_t command_frame_identifier;
	uint8_t capability_information;
}cmd_association_request;

typedef struct cmd_association_response
{
	uint8_t command_frame_identifier;
	uint8_t short_address1;
	uint8_t short_address2;
	//uint16_t short_address;
	uint8_t association_status;
}cmd_association_response;

//disassociacion notification command structure pag. 126
typedef struct cmd_disassociation_notification
{
	uint16_t destination_PAN_identifier;
	uint32_t destination_address0;
	uint32_t destination_address1;
	uint16_t source_PAN_identifier;
	uint32_t source_address0;
	uint32_t source_address1;
	uint8_t command_frame_identifier;
	uint8_t disassociation_reason;
}cmd_disassociation_notification;

//pag 130
typedef struct cmd_beacon_request
{
	uint16_t destination_PAN_identifier;
	uint16_t destination_address;
	uint8_t command_frame_identifier;
}cmd_beacon_request;


//pag 132
typedef struct cmd_gts_request
{
	uint16_t source_PAN_identifier;
	uint16_t source_address;
	uint8_t command_frame_identifier;
	uint8_t gts_characteristics;
}cmd_gts_request;

typedef struct cmd_default
{
	uint8_t command_frame_identifier;
}cmd_default;


//131
typedef struct cmd_coord_realignment
{
	uint8_t command_frame_identifier;
	uint8_t PAN_identifier0;
	uint8_t PAN_identifier1;
	uint8_t coordinator_short_address0;
	uint8_t coordinator_short_address1;
	
	/*
	uint16_t PAN_identifier;
	uint16_t coordinator_short_address;
	*/
	uint8_t logical_channel;
	uint16_t short_address;
}cmd_coord_realignment;



/*******************************************************/
/*     			ADDRESSING FIELDS ONLY				   */
/*******************************************************/
#define DEST_SHORT_LEN 4
#define DEST_LONG_LEN 10
#define INTRA_PAN_SOURCE_SHORT_LEN 2
#define INTRA_PAN_SOURCE_LONG_LEN 8
#define SOURCE_SHORT_LEN 4
#define SOURCE_LONG_LEN 10


//DESTINATION
typedef struct dest_short
{
	uint16_t destination_PAN_identifier;
	uint16_t destination_address;
}dest_short;

typedef struct dest_long
{
	uint16_t destination_PAN_identifier;
	uint32_t destination_address0;
	uint32_t destination_address1;
}dest_long;

//SOURCE
typedef struct intra_pan_source_short
{
	uint16_t source_address;
}intra_pan_source_short;

typedef struct intra_pan_source_long
{
	uint32_t source_address0;
	uint32_t source_address1;
}intra_pan_source_long;


typedef struct source_short
{
	uint16_t source_PAN_identifier;
	uint16_t source_address;
}source_short;


typedef struct source_long
{
	uint16_t source_PAN_identifier;
	uint32_t source_address0;
	uint32_t source_address1;
}source_long;

#endif

