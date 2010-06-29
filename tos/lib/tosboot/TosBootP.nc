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
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 * @author Razvan Musaloiu-E. <razvanm@cs.jhu.edu>
 */

#include "crc.h"
#include <hardware.h>

module TosBootP {
  uses {
    interface Exec;
    interface ExtFlash;
    interface Hardware;
    interface InternalFlash as IntFlash;
    interface Leds;
    interface ProgFlash;
    interface StdControl as SubControl;
    interface Init as SubInit;
    interface Voltage;
  }
}
implementation {

  enum {
    LEDS_LOWBATT = 1,
    LEDS_GESTURE = 7,
  };

  enum {
    R_SUCCESS,
    R_INVALID_IMAGE_ERROR,
    R_PROGRAMMING_ERROR,
  };

  void startupLeds() {

    uint8_t  output = 0x7;
    uint8_t  i;

    for (i = 3; i; i--, output >>= 1 )
      call Leds.glow(output, output >> 1);

  }

  in_flash_addr_t extFlashReadAddr() {
    in_flash_addr_t result = 0;
    int8_t  i;
    for ( i = 3; i >= 0; i-- )
      result |= ((in_flash_addr_t)call ExtFlash.readByte() & 0xff) << (i*8);
    return result;
  }

  bool verifyBlock(ex_flash_addr_t crcAddr, ex_flash_addr_t startAddr, uint16_t len)
  {
    uint16_t crcTarget, crcTmp;

    // read crc
    call ExtFlash.startRead(crcAddr);
    crcTarget = (uint16_t)(call ExtFlash.readByte() & 0xff) << 8;
    crcTarget |= (uint16_t)(call ExtFlash.readByte() & 0xff);
    call ExtFlash.stopRead();

    // compute crc
    call ExtFlash.startRead(startAddr);
    for ( crcTmp = 0; len; len-- )
      crcTmp = crcByte(crcTmp, call ExtFlash.readByte());
    call ExtFlash.stopRead();

    return crcTarget == crcTmp;
  }

  bool verifyImage(ex_flash_addr_t startAddr) {
    uint32_t addr;
    uint8_t  numPgs;
    uint8_t  i;


    if (!verifyBlock(startAddr + offsetof(DelugeIdent,crc),
		     startAddr, offsetof(DelugeIdent,crc)))
      return FALSE;

    // read size of image
    call ExtFlash.startRead(startAddr + offsetof(DelugeIdent,numPgs));
    numPgs = call ExtFlash.readByte();
    call ExtFlash.stopRead();

    if (numPgs == 0 || numPgs == 0xff)
      return FALSE;

    startAddr += DELUGE_IDENT_SIZE;
    addr = DELUGE_CRC_BLOCK_SIZE;

    for ( i = 0; i < numPgs; i++ ) {
      if (!verifyBlock(startAddr + i*sizeof(uint16_t),
		       startAddr + addr, DELUGE_BYTES_PER_PAGE)) {
	return FALSE;
      }
      addr += DELUGE_BYTES_PER_PAGE;
    }

    return TRUE;
  }

  error_t programImage(ex_flash_addr_t startAddr) {
    uint8_t  buf[TOSBOOT_INT_PAGE_SIZE];
    uint32_t pageAddr, newPageAddr;
    in_flash_addr_t intAddr;
    in_flash_addr_t secLength;
    ex_flash_addr_t curAddr;

    if (!verifyImage(startAddr))
      return R_INVALID_IMAGE_ERROR;

    curAddr = startAddr + DELUGE_IDENT_SIZE + DELUGE_CRC_BLOCK_SIZE;

    call ExtFlash.startRead(curAddr);

    intAddr = extFlashReadAddr();
    secLength = extFlashReadAddr();
    curAddr = curAddr + 8;

#if defined(PLATFORM_TELOSB) || defined (PLATFORM_EPIC) || defined (PLATFORM_TINYNODE)
    if (intAddr != TOSBOOT_END) {
#elif defined(PLATFORM_MICAZ) || defined(PLATFORM_IRIS)
    if (intAddr != 0) {
#elif defined(PLATFORM_MULLE)
    if (intAddr != 0xA0000) {
#else
  #error "Target platform is not currently supported by Deluge T2"
#endif
      call ExtFlash.stopRead();
      return R_INVALID_IMAGE_ERROR;
    }

    call ExtFlash.stopRead();

    while ( secLength ) {

      pageAddr = newPageAddr = intAddr / TOSBOOT_INT_PAGE_SIZE;

      call ExtFlash.startRead(curAddr);
      // fill in ram buffer for internal program flash sector
      do {

	// check if secLength is all ones
	if ( secLength == 0xffffffff ) {
	  call ExtFlash.stopRead();
	  return FAIL;
	}

	buf[(uint16_t)intAddr % TOSBOOT_INT_PAGE_SIZE] = call ExtFlash.readByte();
	intAddr++; curAddr++;

	if ( --secLength == 0 ) {
	  intAddr = extFlashReadAddr();
	  secLength = extFlashReadAddr();
	  curAddr = curAddr + 8;
	}

	newPageAddr = intAddr / TOSBOOT_INT_PAGE_SIZE;

      } while ( pageAddr == newPageAddr && secLength );
      call ExtFlash.stopRead();

      call Leds.set(pageAddr);

      // write out page
      if (call ProgFlash.write(pageAddr*TOSBOOT_INT_PAGE_SIZE, buf,
			       TOSBOOT_INT_PAGE_SIZE) == FAIL) {
	return R_PROGRAMMING_ERROR;
      }
    }

    return R_SUCCESS;

  }

  void runApp() {
    call SubControl.stop();
    call Exec.exec();
  }

  void startupSequence() {

    BootArgs args;

    // check voltage and make sure flash can be programmed
    //   if not, just run the app, can't check for gestures
    //   if we can't write to the internal flash anyway
    if ( !call Voltage.okToProgram() ) {
      // give user some time and count down LEDs
      call Leds.flash(LEDS_LOWBATT);
      startupLeds();
      runApp();
    }

    // get current value of counter
    call IntFlash.read((uint8_t*)TOSBOOT_ARGS_ADDR, &args, sizeof(args));

    // increment gesture counter, see if it exceeds threshold
    if ( ++args.gestureCount >= TOSBOOT_GESTURE_MAX_COUNT - 1 ) {
      // gesture has been detected, display receipt of gesture on LEDs
      call Leds.flash(LEDS_GESTURE);

      // load golden image from flash
      // if the golden image is invalid, forget about reprogramming
      // if an error happened during reprogramming, reboot and try again
      //   not much else we can do :-/
      if (programImage(TOSBOOT_GOLDEN_IMG_ADDR) == R_PROGRAMMING_ERROR) {
	call Hardware.reboot();
      }
    }
    else {
      // update gesture counter
      call IntFlash.write((uint8_t*)TOSBOOT_ARGS_ADDR, &args, sizeof(args));
      if ( !args.noReprogram ) {
	// if an error happened during reprogramming, reboot and try again
	//   after two tries, try programming the golden image
	if (programImage(args.imageAddr) == R_PROGRAMMING_ERROR) {
	  call Hardware.reboot();
	}
      }
    }

    // give user some time and count down LEDs
    startupLeds();

    // reset counter and reprogramming flag
    args.gestureCount = 0xff;
    args.noReprogram = TRUE;
    call IntFlash.write((uint8_t*)TOSBOOT_ARGS_ADDR, &args, sizeof(args));

    runApp();

  }

  int main() @C() @spontaneous() {

    __nesc_disable_interrupt();

    TOSH_SET_PIN_DIRECTIONS();
    call Hardware.init();

    call SubInit.init();
    call SubControl.start();

    startupSequence();

    return 0;

  }

}
