/*
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
    async command void initAmAddress(am_group_t myGroup, am_addr_t myAddr);
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
      call initAmAddress(TOS_AM_GROUP, bootArgs.address);
    }

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

}
