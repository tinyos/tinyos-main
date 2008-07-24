// $Id: Tda5250ActiveMessageC.nc,v 1.1 2008-07-24 20:44:04 liang_mike Exp $

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
 * Authors:             Philip Levis
 * Date last modified:  $Id: Tda5250ActiveMessageC.nc,v 1.1 2008-07-24 20:44:04 liang_mike Exp $
 *
 */

/**
 *
 * The Active Message layer for the TDA5250 radio. This configuration
 * just layers the AM dispatch (Tda5250ActiveMessageP) on top of the
 * underlying TDA5250 radio packet.
 *
 * @author Philip Levis
 * @author Vlado Handziski (TDA5250 modifications)
 * @date July 20 2005
 */


#include "Timer.h"

configuration Tda5250ActiveMessageC {
  provides {
    interface SplitControl;
    interface AMSend[am_id_t id];
    interface Receive[am_id_t id];
    interface Receive as ReceiveDefault[am_id_t id];
    interface Receive as Snoop[am_id_t id];
    interface Receive as SnoopDefault[am_id_t id];
    interface AMPacket;
    interface Packet;
    interface PacketAcknowledgements;
    interface Tda5250Packet;	
  }
}
implementation {

  components Tda5250ActiveMessageP as AM, RadioDataLinkC as Radio;
  components ActiveMessageAddressC as Address;

  SplitControl = Radio;

  Packet       = Radio;
  PacketAcknowledgements = Radio;
  Tda5250Packet = AM;		

  AMSend         = AM;
  Receive        = AM.Receive;
  ReceiveDefault = AM.ReceiveDefault;
  Snoop          = AM.Snoop;
  SnoopDefault   = AM.SnoopDefault;
  AMPacket       = AM;

  AM.SubSend    -> Radio.Send;
  AM.SubReceive -> Radio.Receive;
  AM.SubPacket -> Radio.Packet;
  AM.amAddress -> Address;
}
