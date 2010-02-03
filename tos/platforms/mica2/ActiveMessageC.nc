// $Id: ActiveMessageC.nc,v 1.7 2010-02-03 16:49:23 sallai Exp $

/*
 * "Copyright (c) 2004-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/*
 *
 * Authors:		Philip Levis
 * Date last modified:  $Id: ActiveMessageC.nc,v 1.7 2010-02-03 16:49:23 sallai Exp $
 *
 */

/**
 * The Active Message layer on the mica2 platform. This is a naming wrapper
 * around the CC1000 Active Message layer.
 *
 * @author Philip Levis
 * @date June 19 2005
 */

configuration ActiveMessageC {
  provides {
    interface SplitControl;

    interface AMSend[uint8_t id];
    interface Receive[uint8_t id];
    interface Receive as Snoop[uint8_t id];

    interface Packet;
    interface AMPacket;
    interface PacketAcknowledgements;
    interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli; 
    interface PacketTimeStamp<T32khz, uint32_t> as PacketTimeStamp32khz; 
    interface LowPowerListening;
  }
}
implementation {
  components CC1000ActiveMessageC as AM;

  SplitControl = AM;
  
  AMSend       = AM;
  Receive      = AM.Receive;
  Snoop        = AM.Snoop;
  Packet       = AM;
  AMPacket     = AM;
  PacketAcknowledgements = AM;
  PacketTimeStampMilli   = AM;
  PacketTimeStamp32khz   = AM;
  LowPowerListening	 = AM;
}
