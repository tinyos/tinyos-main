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

configuration RadioCountToDiagC
{
}

implementation
{
	components MainC, RadioCountToDiagP, DiagMsgC;
	components ActiveMessageC, SerialActiveMessageC;
	components new TimerMilliC() as SendTimerC;
	components new TimerMilliC() as ReportTimerC;

	RadioCountToDiagP.Boot -> MainC;
	RadioCountToDiagP.DiagMsg -> DiagMsgC;
	RadioCountToDiagP.SendTimer -> SendTimerC;
	RadioCountToDiagP.ReportTimer -> ReportTimerC;

	RadioCountToDiagP.SerialControl -> SerialActiveMessageC;
	RadioCountToDiagP.RadioControl -> ActiveMessageC;

	RadioCountToDiagP.PacketAcknowledgements -> ActiveMessageC;
	RadioCountToDiagP.AMPacket -> ActiveMessageC;
	RadioCountToDiagP.Packet -> ActiveMessageC;
	RadioCountToDiagP.AMSend -> ActiveMessageC.AMSend[0x11];
	RadioCountToDiagP.Receive -> ActiveMessageC.Receive[0x11];

	components ActiveMessageAddressC;
	RadioCountToDiagP.ActiveMessageAddress -> ActiveMessageAddressC;

	RadioCountToDiagP.LowPowerListening -> ActiveMessageC;
}
