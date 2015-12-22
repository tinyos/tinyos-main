/*
 * Copyright (c) 2015, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
 *	author: Tim Bormann (bormann@tkn.tu-berlin.de)
 */

#include <MMAC.h>
#include <Ieee154.h>

module TestC
{
	uses interface Boot;
	uses interface Timer<TMilli> as SendTimer;
	uses interface Timer<TMilli> as LedFlashTimer;
	uses interface Leds;
	uses interface SplitControl;
	uses interface Send;
	uses interface Receive;
	uses interface Jn516PacketBody;
	uses interface Ieee154Address;
}
implementation
{
	#define SEND_INTERVAL 1000
	uint8_t seqno = 0;

	message_t tx_msg;

	event void Boot.booted() {
		jn516_header_t *tx_hdr = call Jn516PacketBody.getHeader(&tx_msg);
		uint8_t* tx_payload;

		tx_hdr->length = 15;
		tx_hdr->fcf = 0x8841;
		tx_hdr->destpan = call Ieee154Address.getPanId();
		tx_hdr->dest = call Ieee154Address.getShortAddr();
		tx_hdr->src = call Ieee154Address.getShortAddr();

		tx_payload = call Jn516PacketBody.getPayload(&tx_msg);

		tx_payload[0] = 0xca;
		tx_payload[1] = 0xfe;
		tx_payload[2] = 0xba;
		tx_payload[3] = 0xbe;

		call SplitControl.start();
	}

	event void SplitControl.startDone(error_t error) {
		call SendTimer.startPeriodic(SEND_INTERVAL);
	}

	event void SendTimer.fired() {
		jn516_header_t *tx_hdr = call Jn516PacketBody.getHeader(&tx_msg);
		seqno++;
		tx_hdr->dsn = seqno;
		call Send.send(&tx_msg,4);
		call Leds.led0Off();
	}

	event void Send.sendDone(message_t* msg, error_t error) {
	}

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		bool correct = TRUE;
		jn516_header_t *rx_hdr = call Jn516PacketBody.getHeader(msg);
		uint8_t* rx_payload = call Jn516PacketBody.getPayload(msg);

		call Leds.led0Off();

		if (rx_hdr->length != 15) correct = FALSE;
		if (rx_hdr->fcf != 0x8841) correct = FALSE;
		if (rx_hdr->destpan != call Ieee154Address.getPanId()) correct = FALSE;
		if (rx_hdr->dest != call Ieee154Address.getShortAddr()) correct = FALSE;
		if (rx_hdr->src != call Ieee154Address.getShortAddr()) correct = FALSE;
		if (rx_payload[0] != 0xca) correct = FALSE;
		if (rx_payload[1] != 0xfe) correct = FALSE;
		if (rx_payload[2] != 0xba) correct = FALSE;
		if (rx_payload[3] != 0xbe) correct = FALSE;

		if (correct) {
			call Leds.led0On();
			call LedFlashTimer.startOneShot(100);
		}

		return msg;
	}

	event void LedFlashTimer.fired() {
		call Leds.led0Off();
	}

	event void SplitControl.stopDone(error_t error) {}
	event void Ieee154Address.changed() {}
}

