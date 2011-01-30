/*
 * Copyright (c) 2010 CSIRO Australia
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
 * - Neither the name of the University of California nor the names of
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
 * @author Kevin Klues <kevin.klues@csiro.au>
 */

generic module MoteP(uint32_t base_addr)
{
  uses {
    interface Boot;
    interface InternalFlash as IFlash;
    interface Leds;
  }
}
implementation {

  __attribute__((noinline)) void verySimpleTest() {
    #define BUFFER0_SIZE 256
  
    uint8_t buf[BUFFER0_SIZE];
    uint8_t *addr;
    uint16_t size;
    int i;
    for(i=0; i<BUFFER0_SIZE; i++) {
      buf[i] = (uint8_t)i;
    }

    addr = (uint8_t*)base_addr + 0x1000;
    size = BUFFER0_SIZE;
    call IFlash.write(addr, buf, size);
    for(i=0; i<size; i++) {
      if(addr[i] != (uint8_t)i) {
        call Leds.led0On();
        while(1);
      }
    }
  }
  __attribute__((noinline)) void simpleTest() {
    #define RELATIVE_ADDR 455
    #define NUM_PAGES 9
    #define PAGE_OFFSET 34
    #define BUFFER1_SIZE (NUM_PAGES*AT91C_IFLASH1_PAGE_SIZE - PAGE_OFFSET)
  
    uint8_t buf[BUFFER1_SIZE];
    uint8_t *addr;
    uint16_t size;
    int i;
    for(i=0; i<BUFFER1_SIZE; i++) {
      buf[i] = (uint8_t)i;
    }

    addr = (uint8_t*)base_addr + 0x10000 + RELATIVE_ADDR;
    size = BUFFER1_SIZE;
    call IFlash.write(addr, buf, size);
    for(i=0; i<size; i++) {
      if(addr[i] != (uint8_t)i) {
        call Leds.led0On();
        while(1);
      }
    }
  }

  __attribute__((noinline)) void testBootArgs() {
    typedef struct BootArgs {
      uint16_t  address;
      uint32_t imageAddr;
      uint8_t  gestureCount;
      bool     noReprogram;
    } BootArgs;
    #define TOSBOOT_ARGS_ADDR AT91C_IFLASH1

    error_t e;
    BootArgs bootArgs;
    BootArgs *iflashArgs = (BootArgs*)TOSBOOT_ARGS_ADDR;

    atomic {
      call IFlash.read((uint8_t*)iflashArgs, &bootArgs, sizeof(bootArgs));

      bootArgs.imageAddr = 25;//imgAddr;
      bootArgs.gestureCount = 0xff;
      bootArgs.noReprogram = FALSE;
      bootArgs.address = 100;//TOS_NODE_ID;

      call IFlash.write((uint8_t*)iflashArgs, &bootArgs, sizeof(bootArgs));
      e = (bootArgs.imageAddr != iflashArgs->imageAddr);
      e = ecombine(e, bootArgs.gestureCount != iflashArgs->gestureCount);
      e = ecombine(e, bootArgs.address != iflashArgs->address);
      e = ecombine(e, bootArgs.noReprogram != iflashArgs->noReprogram);
      if(e) {
          call Leds.led0On();
          while(1);
      }
    }
  }

  event void Boot.booted() {
    verySimpleTest();
//    simpleTest();
//    testBootArgs();
    call Leds.led1On();
  }
}

