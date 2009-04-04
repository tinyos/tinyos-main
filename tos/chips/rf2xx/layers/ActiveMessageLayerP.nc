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

module ActiveMessageLayerP
{
	provides
	{
		interface AMPacket;
		interface AMSend[am_id_t id];
		interface Receive[am_id_t id];
		interface Receive as Snoop[am_id_t id];	
	}

	uses
	{
		interface Send as SubSend;
		interface Receive as SubReceive;
		interface ActiveMessageConfig as Config;
		interface ActiveMessageAddress;
	}
}

implementation
{
/*----------------- Send -----------------*/

	command error_t AMSend.send[am_id_t id](am_addr_t addr, message_t* msg, uint8_t len)
	{
		error_t error;

		error = call Config.checkPacket(msg);
		if( error != SUCCESS )
			return error;

		call AMPacket.setSource(msg, call AMPacket.address());
		call AMPacket.setGroup(msg, call AMPacket.localGroup());
		call AMPacket.setType(msg, id);
		call AMPacket.setDestination(msg, addr);

		return call SubSend.send(msg, len);
	}

	inline event void SubSend.sendDone(message_t* msg, error_t error)
	{
		signal AMSend.sendDone[call AMPacket.type(msg)](msg, error);
	}

	inline command error_t AMSend.cancel[am_id_t id](message_t* msg)
	{
		return call SubSend.cancel(msg);
	}

	default event void AMSend.sendDone[am_id_t id](message_t* msg, error_t error)
	{
	}

	inline command uint8_t AMSend.maxPayloadLength[am_id_t id]()
	{
		return call SubSend.maxPayloadLength();
	}

	inline command void* AMSend.getPayload[am_id_t id](message_t* msg, uint8_t len)
	{
		return call SubSend.getPayload(msg, len);
	}

/*----------------- Receive -----------------*/

	event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t len)
	{
		am_id_t type = call AMPacket.type(msg);

		msg = call AMPacket.isForMe(msg) 
			? signal Receive.receive[type](msg, payload, len)
			: signal Snoop.receive[type](msg, payload, len);

		return msg;
	}

	default event message_t* Receive.receive[am_id_t id](message_t* msg, void* payload, uint8_t len)
	{
		return msg;
	}

	default event message_t* Snoop.receive[am_id_t id](message_t* msg, void* payload, uint8_t len)
	{
		return msg;
	}

/*----------------- AMPacket -----------------*/

	inline command am_addr_t AMPacket.address()
	{
		return call ActiveMessageAddress.amAddress();
	}
 
	inline command am_group_t AMPacket.localGroup()
	{
		return call ActiveMessageAddress.amGroup();
	}

	inline command bool AMPacket.isForMe(message_t* msg)
	{
		am_addr_t addr = call AMPacket.destination(msg);
		return addr == call AMPacket.address() || addr == AM_BROADCAST_ADDR;
	}

	inline command am_addr_t AMPacket.destination(message_t* msg)
	{
		return call Config.destination(msg);
	}
 
	inline command void AMPacket.setDestination(message_t* msg, am_addr_t addr)
	{
		call Config.setDestination(msg, addr);
	}

	inline command am_addr_t AMPacket.source(message_t* msg)
	{
		return call Config.source(msg);
	}

	inline command void AMPacket.setSource(message_t* msg, am_addr_t addr)
	{
		call Config.setSource(msg, addr);
	}

	inline command am_id_t AMPacket.type(message_t* msg)
	{
		return (call Config.getHeader(msg))->type;
	}

	inline command void AMPacket.setType(message_t* msg, am_id_t type)
	{
		(call Config.getHeader(msg))->type = type;
	}
  
	inline command am_group_t AMPacket.group(message_t* msg) 
	{
		return call Config.group(msg);
	}

	inline command void AMPacket.setGroup(message_t* msg, am_group_t grp)
	{
		call Config.setGroup(msg, grp);
	}

	inline async event void ActiveMessageAddress.changed()
	{
	}
}
