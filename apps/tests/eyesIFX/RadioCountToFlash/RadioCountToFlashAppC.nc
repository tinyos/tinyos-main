/*
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
 * This application tests the coexistence of radio and flash.
 * (based on RadioCountToLeds)
 *
 * @see README.TXT
 * @author Philipp Huppertz
 * @author Philip Levis (RadioCountToLeds)
 * @date   June 6 2005
 */

#include "RadioCountToFlash.h"
#include "StorageVolumes.h"


configuration RadioCountToFlashAppC {}
implementation {
  components MainC, RadioCountToFlashC as App, LedsC, PlatformLedsC;
  components new AMSenderC(AM_RADIOCOUNTMSG);
  components new AMReceiverC(AM_RADIOCOUNTMSG);
  components new TimerMilliC() as RadioTimer;
  components new TimerMilliC() as FlashTimer;
  components ActiveMessageC;
  components new LogStorageC(VOLUME_LOGTEST, TRUE);

  
  
  
  App.Boot -> MainC.Boot;
  
  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;
  App.AMControl -> ActiveMessageC;
  App.Leds -> LedsC;
  App.FailureLed -> PlatformLedsC.Led3;
  App.FlashTimer -> FlashTimer;
  App.RadioTimer -> RadioTimer;
  App.Packet -> AMSenderC;
  
  App.LogRead -> LogStorageC.LogRead;
  App.LogWrite -> LogStorageC.LogWrite;
}


