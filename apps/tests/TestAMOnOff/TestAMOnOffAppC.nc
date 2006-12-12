// $Id: TestAMOnOffAppC.nc,v 1.4 2006-12-12 18:22:49 vlahan Exp $

/*									tab:4
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 *  This OSKI test application tests whether OSKI can turn the active
 *  message service on and off. It has two versions: slave and master,
 *  which are set by a command line -D: SERVICE_SLAVE or
 *  SERVICE_MASTER. A master is always on, and transmits data packets
 *  at 1Hz. Every 5s, it transmits a power message. When a slave hears
 *  a data message, it toggles its red led; when it hears a power
 *  message, it turns off its radio, which it turns back on in a few
 *  seconds. This essentially tests whether ActiveMessageC is turning
 *  the radio off appropriately. It uses AM types 240 (power messages)
 *  and 241 (data messages).
 *
 * @author Philip Levis
 * @date   June 19 2005
 */

configuration TestAMOnOffAppC {}
implementation {
  components MainC, TestAMOnOffC as App, LedsC;
  components new AMSenderC(240) as PowerSend;
  components new AMReceiverC(240) as PowerReceive;
  components new AMSenderC(241) as DataSend;
  components new AMReceiverC(241) as DataReceive;
  components new TimerMilliC();
  components ActiveMessageC;
  
  
  
  App.Boot -> MainC.Boot;
  
  App.PowerReceive -> PowerReceive;
  App.PowerSend -> PowerSend;
  App.DataReceive -> DataReceive;
  App.DataSend -> DataSend;

  App.RadioControl -> ActiveMessageC;
  App.Leds -> LedsC;
  App.MilliTimer -> TimerMilliC;
  
}


