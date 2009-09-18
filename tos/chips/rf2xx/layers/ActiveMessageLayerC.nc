/*
 * Copyright (c) 2009, Vanderbilt University
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

configuration ActiveMessageLayerC
{
	provides
	{
		interface AMPacket;
		interface Packet;
		interface AMSend[am_id_t id];
		interface Receive[am_id_t id];
		interface Receive as Snoop[am_id_t id];	
		interface SendNotifier[am_id_t id];
	}

	uses
	{
		interface RadioPacket as SubPacket;
		interface BareSend as SubSend;
		interface BareReceive as SubReceive;
		interface ActiveMessageConfig as Config;
	}
}

implementation
{
	components ActiveMessageLayerP, ActiveMessageAddressC;
	ActiveMessageLayerP.ActiveMessageAddress -> ActiveMessageAddressC;

	AMPacket = ActiveMessageLayerP;
	Packet = ActiveMessageLayerP;
	AMSend = ActiveMessageLayerP;
	Receive = ActiveMessageLayerP.Receive;
	Snoop = ActiveMessageLayerP.Snoop;
	SendNotifier = ActiveMessageLayerP;
	
	SubPacket = ActiveMessageLayerP;
	SubSend = ActiveMessageLayerP;
	SubReceive = ActiveMessageLayerP;
	Config = ActiveMessageLayerP;
}
