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

configuration TestMacC
{
}

implementation
{
	components MainC, TestMacP, DiagMsgC;
	components ActiveMessageC, SerialActiveMessageC;
	components new TimerMilliC() as SendTimerC;
	components new TimerMilliC() as ReportTimerC;

	TestMacP.Boot -> MainC;
	TestMacP.DiagMsg -> DiagMsgC;
	TestMacP.SendTimer -> SendTimerC;
	TestMacP.ReportTimer -> ReportTimerC;

	TestMacP.SerialControl -> SerialActiveMessageC;
	TestMacP.RadioControl -> ActiveMessageC;

	TestMacP.PacketAcknowledgements -> ActiveMessageC;
	TestMacP.AMSend -> ActiveMessageC.AMSend[0x17];
	TestMacP.Receive -> ActiveMessageC.Receive[0x17];
	TestMacP.Snoop -> ActiveMessageC.Snoop[0x17];
}
