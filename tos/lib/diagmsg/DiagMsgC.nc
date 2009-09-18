/*
 * Copyright (c) 2002-2007, Vanderbilt University
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

configuration DiagMsgC
{
	provides interface DiagMsg;
}

implementation 
{
#ifdef DIAGMSG_NONE

components NoDiagMsgC;
	DiagMsg = NoDiagMsgC;

#else

	enum
	{
		AM_DIAG_MSG = 0xB1,
	};

	components DiagMsgP, MainC, SerialActiveMessageC;

	DiagMsg = DiagMsgP.DiagMsg;

	MainC.SoftwareInit -> DiagMsgP.Init;
	DiagMsgP.AMSend -> SerialActiveMessageC.AMSend[AM_DIAG_MSG];
	DiagMsgP.Packet -> SerialActiveMessageC;

#endif
}
