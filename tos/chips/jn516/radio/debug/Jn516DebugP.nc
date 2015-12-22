#include "message.h"
#include <MMAC.h>

module Jn516DebugP
{
	provides interface Jn516Debug;
	uses interface Boot;
	uses interface Leds;
	uses interface StdControl as UartControl;
	uses interface UartByte;
	uses interface Jn516PacketBody;
}
implementation
{
	bool led0on = FALSE;
	bool led1on = FALSE;

	event void Boot.booted() {
		call UartControl.start();
	}

	command void Jn516Debug.led0toggle() {
		if(led0on) {
			call Leds.led0Off();
			led0on = FALSE;
		} else {
			call Leds.led0On();
			led0on = TRUE;
		}
	}

	command void Jn516Debug.led1toggle() {
		if(led1on) {
			call Leds.led1Off();
			led1on = FALSE;
		} else {
			call Leds.led1On();
			led1on = TRUE;
		}
	}

	void serialSendInt16(uint16_t data) {
		call UartByte.send(((uint8_t*)(&data))[1]);
		call UartByte.send(((uint8_t*)(&data))[0]);
	}

	command void Jn516Debug.serialSendMmacFrame(tsMacFrame* frame) {
		int k;
		uint8_t length = sizeof(jn516_header_t) + frame->u8PayloadLength - 1;
		call UartByte.send(length);
		serialSendInt16(frame->u16FCF);
		call UartByte.send(frame->u8SequenceNum);
		serialSendInt16(frame->u16DestPAN);
		serialSendInt16(frame->uDestAddr.u16Short);
		serialSendInt16(frame->uSrcAddr.u16Short);
		for(k=0; k<frame->u8PayloadLength; k++) {
			call UartByte.send(frame->uPayload.au8Byte[k]);
		}
	}

	command void Jn516Debug.serialSendTosFrame(message_t* s_msg) {
		uint8_t k;
		jn516_header_t *s_header = call Jn516PacketBody.getHeader( s_msg );
		for(k=0; k < (s_header->length - 1); k++) {
			call UartByte.send(((uint8_t*)s_header)[k]);
		}
	}

	command void Jn516Debug.serialSendByte(uint8_t byte) {
		call UartByte.send(byte);
	}
}                              
