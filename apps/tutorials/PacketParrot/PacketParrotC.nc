/*                                                                     tab:2
 *
 * "Copyright (c) 2000-2007 The Regents of the University of
 * California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
 * UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
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
  components CC2420CsmaC;
  components new LogStorageC(VOLUME_LOGTEST, TRUE);
  components new TimerMilliC() as Timer0;

  App.Boot -> MainC;
  App.Leds -> LedsC;
  App.Packet -> ActiveMessageC;
  App.AMControl -> ActiveMessageC;
  App.Send -> CC2420CsmaC;
  App.Receive -> CC2420CsmaC;
  App.LogRead -> LogStorageC;
  App.LogWrite -> LogStorageC;
  App.Timer0 -> Timer0;
}
