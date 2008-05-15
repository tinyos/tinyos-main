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

generic configuration DummyLayerC()
{
	provides
	{
		interface SplitControl;
		interface Send;
		interface Receive;
		interface LowPowerListening;

		interface RadioState;
		interface RadioSend;
		interface RadioReceive;
		interface RadioCCA;

		interface DummyConfig as UnconnectedConfig;
	}

	uses 
	{
		interface RadioState as SubState;
		interface RadioSend as SubRadioSend;
		interface RadioReceive as SubRadioReceive;
		interface RadioCCA as SubRadioCCA;
		interface SplitControl as SubControl;
		interface Send as SubSend;
		interface Receive as SubReceive;

		interface DummyConfig as Config;
	}
}

implementation
{
	RadioState = SubState;
	RadioSend = SubRadioSend;
	RadioReceive = SubRadioReceive;
	RadioCCA = SubRadioCCA;

	SplitControl = SubControl;
	Send = SubSend;
	Receive = SubReceive;

	Config = UnconnectedConfig;

	components DummyLayerP;
	LowPowerListening = DummyLayerP.LowPowerListening;
}
