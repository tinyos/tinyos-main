// $Id: BlinkConfigAppC.nc,v 1.5 2007-04-06 01:13:59 prabal Exp $

/*
 * "Copyright (c) 2000-2006 The Regents of the University of
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
 */
#include "StorageVolumes.h"
#include "Timer.h"

/**
 * Application to demonstrate the ConfigStorageC abstraction.  A timer
 * period is read from flash, divided by two, and written back to
 * flash.  An LED is toggled each time the timer fires.
 *
 * @author Prabal Dutta <prabal@cs.berkeley.edu>
 */
configuration BlinkConfigAppC {
}
implementation {
  components BlinkConfigC as App;
  components new ConfigStorageC(VOLUME_CONFIGTEST);
  components MainC, LedsC, PlatformC, SerialActiveMessageC;
  components new TimerMilliC() as Timer0;

  App.Boot   -> MainC.Boot;
  App.Config -> ConfigStorageC.ConfigStorage;
  App.Mount  -> ConfigStorageC.Mount;
  App.Leds   -> LedsC;
  App.Timer0 -> Timer0;
}
