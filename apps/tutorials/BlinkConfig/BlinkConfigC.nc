// $Id: BlinkConfigC.nc,v 1.5 2007-04-06 01:13:59 prabal Exp $

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

/**
 * Application to demonstrate the ConfigStorageC abstraction.  A timer
 * period is read from flash, divided by two, and written back to
 * flash.  An LED is toggled each time the timer fires.
 *
 * @author Prabal Dutta <prabal@cs.berkeley.edu>
 */
#include <Timer.h>

module BlinkConfigC {
  uses {
    interface Boot;
    interface Leds;
    interface ConfigStorage as Config;
    interface Mount as Mount;
    interface Timer<TMilli> as Timer0;
  }
}
implementation {

  typedef struct config_t {
    uint16_t version;
    uint16_t period;
  } config_t;

  enum {
    CONFIG_ADDR = 0,
    CONFIG_VERSION = 1,
    DEFAULT_PERIOD = 1024
  };

  uint8_t state;
  config_t conf;

  event void Boot.booted() {
    if (call Mount.mount() != SUCCESS) {
      // Handle failure
    }
  }

  event void Mount.mountDone(error_t error) {
    if (error != SUCCESS) {
      // Handle failure
    }
    else{
      if (call Config.read(CONFIG_ADDR, &conf, sizeof(conf)) != SUCCESS) {
	// Handle failure
      }
    }
  }

  event void Config.readDone(storage_addr_t addr, void* buf, 
    storage_len_t len, error_t err) __attribute__((noinline)) {

    if (err == SUCCESS) {
      memcpy(&conf, buf, len);
      if (conf.version == CONFIG_VERSION) {
        conf.period = conf.period > 128 ? conf.period/2 : DEFAULT_PERIOD;
      }
      else {
        // Version mismatch. Restore default.
	call Leds.led1On();
        conf.version = CONFIG_VERSION;
        conf.period = DEFAULT_PERIOD;
      }
      call Leds.led0On();
      call Config.write(CONFIG_ADDR, &conf, sizeof(conf));
    }
    else {
      // Handle failure.
    }
  }

  event void Config.writeDone(storage_addr_t addr, void *buf, 
    storage_len_t len, error_t err) {
    // Verify addr and len

    if (err == SUCCESS) {
      if (call Config.commit() != SUCCESS) {
        // Handle failure
      }
    }
    else {
      // Handle failure
    }
  }

  event void Config.commitDone(error_t err) {
    call Leds.led0Off();
    call Timer0.startPeriodic(conf.period);
    if (err == SUCCESS) {
      // Handle failure
    }
  }

  event void Timer0.fired() {
    call Leds.led2Toggle();
  }
}
