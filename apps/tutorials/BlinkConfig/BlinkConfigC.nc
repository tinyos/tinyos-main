// $Id: BlinkConfigC.nc,v 1.1 2006-11-05 08:01:02 prabal Exp $

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

module BlinkConfigC {
  uses {
    interface Boot;
    interface Leds;
    interface ConfigStorage as Config;
    interface AMSend;
    interface SplitControl as AMControl;
    interface Mount as Mount;
  }
}
implementation {
  uint16_t period = 2048;
  uint16_t period2 = 1024;

  enum {
    CONFIG_ADDR = 0,
  };

  event void Boot.booted() {
    call AMControl.start();
  }

  event void AMControl.startDone(error_t error) {
    if (error != SUCCESS) {
      call AMControl.start();
    }
    if (call Mount.mount() != SUCCESS) {
      // Handle failure
    }
  }

  event void Mount.mountDone(error_t error) {
    if (error != SUCCESS) {
      // Handle failure
    }
    else{
      call Config.write(CONFIG_ADDR, &period, sizeof(period));
    }
  }

  event void Config.writeDone(storage_addr_t addr, void *buf, 
    storage_len_t len, error_t result) {
    // Verify addr and len

    if (result == SUCCESS) {
      // Note success
    }
    else {
      // Handle failure
    }
    if (call Config.commit() != SUCCESS) {
      // Handle failure
    }
  }

  event void Config.commitDone(error_t error) {
    if (call Config.read(CONFIG_ADDR, &period2, sizeof(period2)) != SUCCESS) {
      // Handle failure
    }
  }

  event void Config.readDone(storage_addr_t addr, void* buf, 
    storage_len_t len, error_t result) __attribute__((noinline)) {
    memcpy(&period2, buf, len);

    if (period == period2) {
      call Leds.led2On();
    }

    if (len == 2 && addr == CONFIG_ADDR) {
      call Leds.led1On();
    }
  }

  event void AMSend.sendDone(message_t* msg, error_t error) {
    if (error != SUCCESS) {
      call Leds.led0On();
    }
  }

  event void AMControl.stopDone(error_t error) {
  }
}
