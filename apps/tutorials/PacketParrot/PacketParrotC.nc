/*                                                                     tab:2
 *
 * Copyright (c) 2000-2007 The Regents of the University of
 * California.  All rights reserved.
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
 * - Neither the name of the copyright holders nor the names of
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
 */

/**
 * Demonstrates the <code>LogRead</code> and <code>LogWrite</code>
 * abstractions.  The application logs packets it receives from the
 * radio to flash.  On a subsequent power cycle, the application
 * transmits logged packets, erases the log, and then continues to log
 * packets again.  The red LED is on when the log is being erased.
 * The blue (yellow) LED blinks when packets are being received and
 * logged, and remains on when packets are being received but are not
 * logged (because the log is being erased).  The green LED blinks
 * rapidly after a power cycle when logged packets are transmitted.
 *
 * @author Prabal Dutta
 * @date   Apr 6, 2007
 * @author Janos Sallai
 * @date   Jan 25, 2012 
 */
#include <Timer.h>
#include "StorageVolumes.h"

configuration PacketParrotC {
}
implementation {
  components MainC;
  components LedsC;
  components PacketParrotP as App;
  components ActiveMessageC;
  components new LogStorageC(VOLUME_LOGTEST, TRUE);
  components new TimerMilliC() as Timer0;

  App.Boot -> MainC;
  App.Leds -> LedsC;
  App.Packet -> ActiveMessageC;
  App.AMPacket -> ActiveMessageC;
  App.AMControl -> ActiveMessageC;
  App.AMSend -> ActiveMessageC;
  App.Receive -> ActiveMessageC.Receive;
  App.Snoop -> ActiveMessageC.Snoop;
  App.LogRead -> LogStorageC;
  App.LogWrite -> LogStorageC;
  App.Timer0 -> Timer0;
}
