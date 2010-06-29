// $Id: TestAMOnOffAppC.nc,v 1.5 2010-06-29 22:07:20 scipio Exp $

/*									tab:4
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the University of California nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
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


