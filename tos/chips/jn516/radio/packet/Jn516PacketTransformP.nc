#include "message.h"
#include "Jn516.h"

module Jn516PacketTransformP {
	provides {
		interface Jn516PacketTransform;
	}
	uses {
		interface Jn516PacketBody;
	}
}
implementation {

	async command error_t Jn516PacketTransform.TosToMMAC(message_t* from, tsMacFrame* to) {
    	jn516_header_t *from_hdr = call Jn516PacketBody.getHeader(from);
//		void* from_payload = (void*)(call Jn516PacketBody.getPayload(from));
		void* from_payload = (void*)(&(from_hdr->network));
		void* to_payload = (void*)(to->uPayload.au8Byte);
		uint8_t to_payload_length = from_hdr->length - sizeof(jn516_header_t) + 1;

		to->u8PayloadLength = to_payload_length;
		to->u8SequenceNum = from_hdr->dsn;
		to->u16FCF = from_hdr->fcf;
		to->u16DestPAN = from_hdr->destpan;
		to->u16SrcPAN = from_hdr->destpan;
		to->uDestAddr.u16Short = from_hdr->dest;
		to->uSrcAddr.u16Short = from_hdr->src;

		memcpy(to_payload,from_payload,to_payload_length);

//#ifndef TFRAMES_ENABLED
//		to_payload_length = from_hdr->length - sizeof(jn516_header_t) ;
//		to->u8PayloadLength = to_payload_length;

//		to->uPayload.au8Byte[0] = from_hdr->network;
//		to->uPayload.au8Byte[1] = from_hdr->type;
//		to_payload = (void*)(&(to->uPayload.au8Byte[2]));
//		memcpy(to_payload,from_payload,to_payload_length-2);
//#else
//		to_payload_length = from_hdr->length - sizeof(jn516_header_t) + 1;
//		to->u8PayloadLength = to_payload_length;

//		to->uPayload.au8Byte[0] = from_hdr->type;
//		to_payload = (void*)(&(to->uPayload.au8Byte[1]));
//		memcpy(to_payload,from_payload,to_payload_length-1);
//#endif

		return SUCCESS;
	}

	async command error_t Jn516PacketTransform.MMACToTos(tsMacFrame* from, message_t* to) {
    	jn516_header_t *to_hdr = call Jn516PacketBody.getHeader(to);
//		uint8_t* to_payload /* = (void*)(call Jn516PacketBody.getPayload(to))*/;
		void* to_payload = (void*)(((uint8_t*)to)+10);//(&(to_hdr->network));
		void* from_payload = (void*)(from->uPayload.au8Byte);
		uint8_t from_payload_length = from->u8PayloadLength;


//		uint8_t dummy_payload[128];
//		memset(dummy_payload,0xFF,128);


//		to_hdr->network = 0xCA;
//		to_hdr->type = 0xFE;

//		to_hdr->network = from->uPayload.au8Byte;
//		to_hdr->type = from->uPayload.au8Byte[1];

//		memset(to_payload,0xFF,from->u8PayloadLength);

//		from_payload = (void*)(from->uPayload.au8Byte);
//		to_payload = ((uint8_t*)to) + sizeof(jn516_header_t); //network and type field are in mmac payload, but in tos header .. 

//		memcpy(to_payload,from_payload,from_payload_length-2);

		to_hdr->length = sizeof(jn516_header_t) /*12*/ + from->u8PayloadLength /*18*/ - 1; //-2 ?!?!
		to_hdr->fcf = from->u16FCF;
		to_hdr->dsn = from->u8SequenceNum;
		to_hdr->destpan = from->u16DestPAN;
		to_hdr->dest = from->uDestAddr.u16Short;
		to_hdr->src = from->uSrcAddr.u16Short;

		memcpy(to_payload,from_payload,from_payload_length);

//#ifndef TFRAMES_ENABLED
//		to_hdr->network = from->uPayload.au8Byte[0];
//		to_hdr->type = from->uPayload.au8Byte[1];
//		from_payload = (void*)(&(from->uPayload.au8Byte[2]));
//		memcpy(to_payload,from_payload,from_payload_length-2);
//#else
//		to_hdr->type = from->uPayload.au8Byte[0];
//		from_payload = (void*)(&(from->uPayload.au8Byte[1]));
//		memcpy(to_payload,from_payload,from_payload_length-1);
//#endif

		return SUCCESS;
	}

}

