/*
 * Copyright (c) 2009 Communication Group and Eislab at
 * Lulea University of Technology
 *
 * Contact: Laurynas Riliskis, LTU
 * Mail: laurynas.riliskis@ltu.se
 * All rights reserved.
 *
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of Communication Group at Lulea University of Technology
 *   nor the names of its contributors may be used to endorse or promote
 *    products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "M16c62pFlash.h"
#include "iom16c62p.h"

/**
 * Implementation of the HplM16c62pFlash interface. Note that this module
 * should be used with caution so that one doesn't erase the flash where the
 * executing program lies.
 * 
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 * @author Renesas
 */
// TODO(henrik) This implementation expects a main clock speed <=10 MHz, fix it.
module HplM16c62pFlashC
{
  provides interface HplM16c62pFlash;
}
implementation
{

// Defines an array of highest even addresses for each block
const unsigned long block_addresses[14] =
  {0xFFFFE,0xFEFFE,0xFDFFE,0xFBFFE,0xF9FFE,0xF7FFE,0xEFFFE,0xDFFFE,0xCFFFE,
   0xBFFFE,0xAFFFE,0x9FFFE,0x8FFFE,0xFFFE };
  
unsigned char cm0_saved;			// For saving the Clock Mode 0 register
unsigned char cm1_saved;			// For saving the Clock Mode 1 register
unsigned char pm0_saved;			// For saving the Processor Mode 0 register
unsigned char pm1_saved;			// For saving the Processor Mode 1 register
unsigned char prcr_saved;			//  Save Protection register
  
/**   
 * Sets the processor mode for programming flash and saves current
 * settings to restore later. You cannot run the processor faster
 * than 10.0 MHz (with wait state) or 6.25MHz (without wait state)
 * when sending commands to the flash controller.
 */
void SlowMCUClock(void)
{
  // Unprotect registers CM0 and CM1 and PM0 registers by writting to protection register
  prcr_saved = *((char *)0xA);	// Save Protection register
  *((char *)0xA) = 3;				// Allow writting to protected system registers
  // Force to Single chip mode for processors that have memory expansion mode
  pm0_saved = *((char *)0x4);				// Save pm0 register
  *((char *)0x4) = pm0_saved & 0xFC;		// bit 0 and 1 to zero

  cm0_saved = *((char *)0x6);		// Save cm0 register
  cm1_saved = *((char *)0x7);		// Save cm1 register
  pm1_saved = *((char *)0x5);		// Save pm1 register

  // Insert Wait state for all bus access (needed for talking to the
  // internal flash controller)
  asm("BSET	7,0x05"); // Set bit PM17
  CM0.BYTE = 0;
  CM1.BYTE = 0;
}

/**
 * Restores the processor mode back to original settings.
 */
void RestoreMCUClock(void)			
{
  *((char *)0x4) = pm0_saved;		// Restore pm0 register

  /* Clock settings for R8C and M16C */
  *((char *)0x7) = cm1_saved;		// Restore cm1 register
  *((char *)0x6) = cm0_saved;		// Restore cm0 register
  *((char *)0x5) = pm1_saved;		// Restore pm1 register
  *((char *)0xA) = prcr_saved;	// Protection back on
}

command bool HplM16c62pFlash.FlashErase( unsigned char block )
{
    unsigned int low = (unsigned int) block_addresses[ block ];
    unsigned int high = (unsigned int)( block_addresses[ block ] >> 16);

	// Must change main clock speed to meet flash requirements
	SlowMCUClock();			
        FMR0.BIT.FMR01 = 0;
        FMR0.BIT.FMR01 = 1;
        FMR1.BIT.FMR11 = 0;
        FMR1.BIT.FMR11 = 1;

    asm volatile ("mov.w %[low], a0\n\t"
                  "mov.w %[high], a1\n\t"
                  
                  "mov.w #0x0050, r0\n\t"
                  "ste.w r0, [a1a0]\n\t"
                  
                  "mov.w #0x0020, r0\n\t"
                  "ste.w r0, [a1a0]\n\t"
                  
                  "mov.w #0x00D0, r0\n\t"
                  "ste.w r0, [a1a0]\n\t"
                  :
                  :[low] "r" (low), [high] "r" (high)
                  : "memory", "r0", "a0", "a1");

	// Note: In EW1 Mode, the MCU is suspended until the operation is completed.
    while (!FMR0.BIT.FMR00);
	// Disable CPU rewriting commands by clearing EW entry bit.
	FMR0.BYTE = 0;

	RestoreMCUClock(); // Restore clock back to original speed

	if( FMR0.BIT.FMR07)	// Erasing error?
	{
		return 1;  // Erase Fail
	}

	return 0;  // Erase Pass
}

command uint8_t HplM16c62pFlash.FlashWrite( unsigned long flash_addr,
			     unsigned int * buffer_addr,
			     unsigned int bytes)
{
  unsigned char ret_value = 0;
  unsigned int low = (unsigned int) flash_addr;
  unsigned int high = (unsigned int)( flash_addr >> 16);
  unsigned int i;
  // Check for odd number of bytes 
  if( bytes & 1)
    return 2;	// ERROR!! You must always pass an even number of bytes.

  // Check for odd address
  if( (int)flash_addr & 1)
    return 2;	// ERROR!! You must always pass an even flash address

  // Must change main clock speed to meet flash requirements
  SlowMCUClock();			

  FMR0.BIT.FMR01 = 0;
  FMR0.BIT.FMR01 = 1;
  FMR1.BIT.FMR11 = 0;
  FMR1.BIT.FMR11 = 1;

  // Clear status register
  asm volatile ("mov.w %[low], a0\n\t"
      "mov.w %[high], a1\n\t"

      "mov.w #0x0050, r0\n\t"
      "ste.w r0, [a1a0]\n\t"
      :
      :[low] "r" (low), [high] "r" (high)
      : "memory", "r0", "a1", "a0");

  for (i = 0; i < (bytes >> 1); ++i)
  {
    // Write to the flash sequencer by writing to that area of flash memory
    asm volatile (
        "mov.w %[low], a0\n\t"
        "mov.w %[high], a1\n\t"

        "mov.w #0x0040, r1\n\t" // Send write command
        "ste.w r1, [a1a0]\n\t"

        "mov.w %[data], r1\n\t" // Write data
        "ste.w r1, [a1a0]\n\t"
        :
        :[low] "r" (low), [high] "r" (high), [data] "r" (*buffer_addr)
        : "memory", "a1", "a0", "r1");

    // Note: In EW1 Mode, the MCU is suspended until the operation completed

    // Read flash program status flag
    if( FMR0.BIT.FMR06 ) // Write error?
    {
      ret_value = 1;		// Signal that we had got an error
      break;				// Break out of while loop
    }

    flash_addr += 2;		// Advance to next flash write address
    buffer_addr++;			// Advance to next data buffer address
    low = (unsigned int) flash_addr;
    high = (unsigned int)( flash_addr >> 16);
  }

    asm volatile ("mov.w %[low], a0\n\t"
                  "mov.w %[high], a1\n\t"
                  "ste.w 0x00FF, [a1a0]\n\t"
                  :
                  :[low] "r" (low), [high] "r" (high)
                  : "memory", "a0", "a1");

  // Disable CPU rewriting commands by clearing EW entry bit
  FMR0.BYTE = 0;
  RestoreMCUClock();		// Restore clock back to original speed

  return ret_value;		// Return Pass/Fail
}

command uint8_t HplM16c62pFlash.FlashRead(unsigned long address) {
  unsigned int low = (unsigned int)(address);
  unsigned int high = (unsigned int)(address >> 16);
  unsigned int data;
  asm volatile ("mov.w %[low], a0\n\t"
                "mov.w %[high], a1\n\t"
                "ste.w 0x00FF, [a1a0]\n\t"
                "lde.w [a1a0], %[data]"
                :[data] "=r" (data)
                :[low] "r" (low), [high] "r" (high)
                : "memory", "a0", "a1");
  return data;
}
}
