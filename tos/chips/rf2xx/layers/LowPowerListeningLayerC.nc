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

#warning "*** USING LOW POWER LISTENING LAYER"

configuration LowPowerListeningLayerC
{
	provides
	{
		interface SplitControl;
		interface Send;
		interface Receive;
		interface RadioPacket;

		interface LowPowerListening;
	}
	uses
	{
		interface SplitControl as SubControl;
		interface Send as SubSend;
		interface Receive as SubReceive;
		interface RadioPacket as SubPacket;

		interface LowPowerListeningConfig as Config;
		interface PacketAcknowledgements;
	}
}

implementation
{
	components LowPowerListeningLayerP, new TimerMilliC();

	SplitControl = LowPowerListeningLayerP;
	Send = LowPowerListeningLayerP;
	Receive = LowPowerListeningLayerP;
	RadioPacket = LowPowerListeningLayerP;
	LowPowerListening = LowPowerListeningLayerP;

	SubControl = LowPowerListeningLayerP;
	SubSend = LowPowerListeningLayerP;
	SubReceive = LowPowerListeningLayerP;
	SubPacket = LowPowerListeningLayerP;
	Config = LowPowerListeningLayerP;
	PacketAcknowledgements = LowPowerListeningLayerP;
	
	LowPowerListeningLayerP.Timer -> TimerMilliC;
}
