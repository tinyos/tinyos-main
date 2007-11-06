/*
 * Copyright (c) 2007, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Miklos Maroti
 */

#include <Tasklet.h>
#include <DefaultMac.h>
#include <message.h>

module RF230SnifferP
{
	uses
	{
		interface Boot;
		interface SplitControl;

		interface RadioState;
		interface IEEE154Packet;
	}

	provides 
	{
		interface RF230Config;
	}
}

implementation
{
	task void serialPowerUp()
	{
		if( call SplitControl.start() != SUCCESS )
			post serialPowerUp();
	}

	event void SplitControl.startDone(error_t error)
	{
		if( error != SUCCESS )
			post serialPowerUp();
		else
			call RadioState.turnOn();
	}

	event void SplitControl.stopDone(error_t error)
	{
	}

	event void Boot.booted()
	{
		post serialPowerUp();
	}

	tasklet_async event void RadioState.done()
	{
	}

	async command uint8_t RF230Config.getLength(message_t* msg)
	{
		return call IEEE154Packet.getLength(msg);
	}

	async command void RF230Config.setLength(message_t* msg, uint8_t len)
	{
		call IEEE154Packet.setLength(msg, len);
	}

	async command uint8_t* RF230Config.getPayload(message_t* msg)
	{
		return ((uint8_t*)(call IEEE154Packet.getHeader(msg))) + 1;
	}

	inline defaultmac_metadata_t* getMeta(message_t* msg)
	{
		return (defaultmac_metadata_t*)(msg->metadata);
	}

	async command void RF230Config.setTimestamp(message_t* msg, uint16_t time)
	{
		getMeta(msg)->timestamp = time;
	}

	async command void RF230Config.setLinkQuality(message_t* msg, uint8_t lqi)
	{
		getMeta(msg)->lqi = lqi;
	}

	async command uint8_t RF230Config.getHeaderLength()
	{
		// we need the fcf, dsn, destpan and dest
		return 7;
	}

	async command uint8_t RF230Config.getMaxLength()
	{
		// note, that the ieee154_footer_t is not stored, but we should include it here
		return sizeof(defaultmac_header_t) - 1 + TOSH_DATA_LENGTH + sizeof(ieee154_footer_t);
	}

	async command uint8_t RF230Config.getTransmitPower(message_t* msg)
	{
		return 0;
	}

	async command uint8_t RF230Config.getDefaultChannel()
	{
		return RF230_DEF_CHANNEL;
	}
}
