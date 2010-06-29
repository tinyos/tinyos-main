// $Id: ExtFlashC.nc,v 1.2 2010-06-29 22:07:51 scipio Exp $

/*
 *
 *
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
 */

/**
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 * @author Roland Flury <roland.flury@shockfish.com>
 */

module ExtFlashC {
  provides {
    interface Init;
    interface StdControl;
    interface ExtFlash;
  }
}

/**
 * Simple reader module to access the Atmel at45db041 flash chip
 */
implementation {

  uint32_t addr;

  command error_t Init.init() {

    TOSH_SET_FLASH_CS_PIN(); // inverted, deselect by default
    TOSH_MAKE_FLASH_CS_OUTPUT();

    TOSH_CLR_FLASH_CLK_PIN();
    TOSH_MAKE_FLASH_CLK_OUTPUT();

    TOSH_SET_FLASH_OUT_PIN();
    TOSH_MAKE_FLASH_OUT_OUTPUT();      

    TOSH_MAKE_FLASH_IN_INPUT();

		TOSH_SET_FLASH_RESET_PIN(); // inverted
		TOSH_MAKE_FLASH_RESET_OUTPUT();

    return SUCCESS; 
  }

  command error_t StdControl.start() { return SUCCESS; }
  command error_t StdControl.stop() { return SUCCESS; }
	
	/**
	 * Write a Byte over the SPI bus and receive a Byte
	 *
	 * upon calling this function, /CS must be CLR
	 */
  uint8_t SPIByte(uint8_t out) {
    uint8_t in = 0;
    uint8_t i;

    for ( i = 0; i < 8; i++, out <<= 1 ) {
      // write bit
      if (out & 0x80) {
				TOSH_SET_FLASH_OUT_PIN();
			} else {
				TOSH_CLR_FLASH_OUT_PIN();
			}
			
      // clock
      TOSH_SET_FLASH_CLK_PIN();
			
      // read bit
      in <<= 1;
      if (TOSH_READ_FLASH_IN_PIN()) {
				in |= 1;
			}
			
      // clock
      TOSH_CLR_FLASH_CLK_PIN();
    }

    return in;
  }



	/**
	 * Initializes the flash to read Byte after Byte starting
	 * from the given address. 
	 *
	 * Subsequent calls to readByte() will return the Bytes 
	 * starting from the specified address. 
	 *
	 * stopRead() terminates this process and disables the Flash. 
	 */
  command void ExtFlash.startRead(uint32_t newAddr) {
    uint8_t  cmdBuf[4];
    uint8_t  i;

		// we're using "Waveform 1 - Inactive Clock Polarity Low"
		// see p.7 of data sheet
    TOSH_CLR_FLASH_CLK_PIN(); 
    TOSH_CLR_FLASH_CS_PIN(); // select the flash

    addr = newAddr;

		// we only use 256 Bytes per block (of 264 Bytes)
    cmdBuf[0] = 0x52; // command for reading data starting at the following address
    cmdBuf[1] = (addr >> 15) & 0xff; // 4 LSbits 
    cmdBuf[2] = (addr >> 7) & 0xfe;  // 7 MSbits with the above 4 bits describe page to read
    cmdBuf[3] = addr & 0xff;         // Offset to Byte in page to read

		// transmit read command
    for(i = 0; i < 4; i++) {
      SPIByte(cmdBuf[i]);
		}
		// transmit 4 Bytes "don't care" as to spec
    for(i = 0; i < 4; i++) {
      SPIByte(0x0);
		}
    
		// need to do one additional clock transition before reading
		TOSH_SET_FLASH_CLK_PIN();
		TOSH_CLR_FLASH_CLK_PIN();
  }

  command uint8_t ExtFlash.readByte() {
		uint8_t b = SPIByte(0); // write anything, read Byte
		addr++;
		if(0 == (addr & 0xFF)) {
			// we've just read the last Byte from a page
			// initialize the Flash to continue reading on the new page
      call ExtFlash.stopRead();
      call ExtFlash.startRead(addr);
		} 
		return b;
  }

  command void ExtFlash.stopRead() {
    TOSH_SET_FLASH_CS_PIN(); // disble Flash & tri-state the OUT-pin
  }

}
