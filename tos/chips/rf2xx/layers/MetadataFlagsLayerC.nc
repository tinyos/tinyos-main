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

#include <MetadataFlagsLayer.h>
#include <RadioAssert.h>

module MetadataFlagsLayerC
{
	provides 
	{
		interface PacketFlag[uint8_t bit];
	}

	uses
	{
		interface PacketData<flags_metadata_t> as PacketFlagsMetadata;
	}
}

implementation
{
	async command bool PacketFlag.get[uint8_t bit](message_t* msg)
	{
		return (call PacketFlagsMetadata.get(msg))->flags & (1<<bit);
	}

	async command void PacketFlag.set[uint8_t bit](message_t* msg)
	{
		ASSERT( bit  < 8 );

		(call PacketFlagsMetadata.get(msg))->flags |= (1<<bit);
	}

	async command void PacketFlag.clear[uint8_t bit](message_t* msg)
	{
		ASSERT( bit  < 8 );

		(call PacketFlagsMetadata.get(msg))->flags &= ~(1<<bit);
	}

	async command void PacketFlag.setValue[uint8_t bit](message_t* msg, bool value)
	{
		if( value )
			call PacketFlag.set[bit](msg);
		else
			call PacketFlag.clear[bit](msg);
	}

	async event void PacketFlagsMetadata.clear(message_t* msg)
	{
		(call PacketFlagsMetadata.get(msg))->flags = 0;
	}
}
