// $Id: BlinkConfigAppC.nc,v 1.4 2006-12-12 18:22:52 vlahan Exp $

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

/**
 * Application to demonstrate the ConfigStorageC abstraction.  A value
 * is written to, and read from, the flash storage. A successful test
 * will turn on both the green and blue (yellow) LEDs.  A failed test
 * is any other LED configuration.
 *
 * @author Prabal Dutta
 */
configuration BlinkConfigAppC {
}
implementation {
  components BlinkConfigC as App;
  components new ConfigStorageC(VOLUME_CONFIGTEST);
  components MainC, LedsC, PlatformC, SerialActiveMessageC;

  App.Boot -> MainC.Boot;

  App.AMControl -> SerialActiveMessageC;
  App.AMSend    -> SerialActiveMessageC.AMSend[1];
  App.Config    -> ConfigStorageC.ConfigStorage;
  App.Mount     -> ConfigStorageC.Mount;
  App.Leds      -> LedsC;
}
