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
 * Copyright (c) 2007 Johns Hopkins University.
 * All rights reserved.
 *
 */

/**
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 * @author Razvan Musaloiu-E. <razvanm@cs.jhu.edu>
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 */

#include "AM.h"

module NetProgM {
  provides {
    interface NetProg;
    interface Init;
  }
  uses {
    interface InternalFlash as IFlash;
    interface Crc;
    interface Leds;
    interface CC2420Config;
    async command void setAmAddress(am_addr_t a);
  }
}

implementation {

  command error_t Init.init()
  {
    BootArgs bootArgs;
    call IFlash.read((uint8_t*)TOSBOOT_ARGS_ADDR, &bootArgs, sizeof(bootArgs));

    // Update the local node ID
    if (bootArgs.address != 0xFFFF) {
      TOS_NODE_ID = bootArgs.address;
      call setAmAddress(bootArgs.address);
    }
    call CC2420Config.setShortAddr(bootArgs.address);
    call CC2420Config.sync();
    
    return SUCCESS;
  }
  
  command error_t NetProg.reboot()
  {
    BootArgs bootArgs;

    atomic {
      call IFlash.read((uint8_t*)TOSBOOT_ARGS_ADDR, &bootArgs, sizeof(bootArgs));

      if (bootArgs.address != TOS_NODE_ID) {
	bootArgs.address = TOS_NODE_ID;
	call IFlash.write((uint8_t*)TOSBOOT_ARGS_ADDR, &bootArgs, sizeof(bootArgs));
      }
      netprog_reboot();
    }

    return FAIL;
  }
  
  command error_t NetProg.programImageAndReboot(uint32_t imgAddr)
  {
    BootArgs bootArgs;

    atomic {
      call IFlash.read((uint8_t*)TOSBOOT_ARGS_ADDR, &bootArgs, sizeof(bootArgs));
      
      bootArgs.imageAddr = imgAddr;
      bootArgs.gestureCount = 0xff;
      bootArgs.noReprogram = FALSE;
      bootArgs.address = TOS_NODE_ID;

      call IFlash.write((uint8_t*)TOSBOOT_ARGS_ADDR, &bootArgs, sizeof(bootArgs));

      // reboot
      netprog_reboot();
    }

    // couldn't reboot
    return FAIL;
  }

  event void CC2420Config.syncDone(error_t error) {}

}
