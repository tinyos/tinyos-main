// $Id: BlinkConfigC.nc,v 1.7 2010-06-29 22:07:40 scipio Exp $

/*
 * Copyright (c) 2000-2006 The Regents of the University of
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
    DEFAULT_PERIOD = 1024,
    MIN_PERIOD     = 128,
    MAX_PERIOD     = 1024
  };

  uint8_t state;
  config_t conf;

  event void Boot.booted() {
    conf.period = DEFAULT_PERIOD;

    if (call Mount.mount() != SUCCESS) {
      // Handle failure
    }
  }

  event void Mount.mountDone(error_t error) {
    if (error == SUCCESS) {
      if (call Config.valid() == TRUE) {
        if (call Config.read(CONFIG_ADDR, &conf, sizeof(conf)) != SUCCESS) {
          // Handle failure
	}
      }
      else {
	// Invalid volume.  Commit to make valid.
	call Leds.led1On();
	if (call Config.commit() == SUCCESS) {
	  call Leds.led0On();
	}
	else {
	  // Handle failure
	}
      }
    }
    else{
      // Handle failure
    }
  }

  event void Config.readDone(storage_addr_t addr, void* buf, 
    storage_len_t len, error_t err) __attribute__((noinline)) {

    if (err == SUCCESS) {
      memcpy(&conf, buf, len);
      if (conf.version == CONFIG_VERSION) {
        conf.period = conf.period/2;
	conf.period = conf.period > MAX_PERIOD ? MAX_PERIOD : conf.period;
        conf.period = conf.period < MIN_PERIOD ? MAX_PERIOD : conf.period;
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
