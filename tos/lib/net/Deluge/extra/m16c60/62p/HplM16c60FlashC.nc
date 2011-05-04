/*
 * Copyright (c) 2011 Lulea University of Technology
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
 */

#include "M16c62pFlash.h"
#include "iom16c62p.h"
/**
 * Implementation of the HplM16c60Flash interface for M16c/62p. Note that this module
 * should be used with caution so that one doesn't erase the flash where the
 * executing program lies.
 * 
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 * @author Renesas
 */
// TODO(henrik) This implementation expects a main clock speed <=10 MHz, fix it.
module HplM16c60FlashC
{
  provides interface HplM16c60Flash;
}
implementation
{

  // Defines an array of highest even addresses for each block
  const unsigned long block_addresses[14] =
  {0xFFFFE,0xFEFFE,0xFDFFE,0xFBFFE,0xF9FFE,0xF7FFE,0xEFFFE,0xDFFFE,0xCFFFE,
    0xBFFFE,0xAFFFE,0x9FFFE,0x8FFFE,0xFFFE };

  unsigned char cm0_saved; // For saving the Clock Mode 0 register
  unsigned char cm1_saved; // For saving the Clock Mode 1 register
  unsigned char pm0_saved; // For saving the Processor Mode 0 register
  unsigned char pm1_saved; // For saving the Processor Mode 1 register
  unsigned char prcr_saved; //  Save Protection register

  /**   
   * Sets the processor mode for programming flash and saves current
   * settings to restore later. You cannot run the processor faster
   * than 10.0 MHz (with wait state) or 6.25MHz (without wait state)
   * when sending commands to the flash controller.
   */
  void slowMCUClock(void)
  {
    // Unprotect registers CM0 and CM1 and PM0 registers by writting to protection register
    prcr_saved = *((char *)0xA); // Save Protection register
    *((char *)0xA) = 3; // Allow writting to protected system registers
    // Force to Single chip mode for processors that have memory expansion mode
    pm0_saved = *((char *)0x4); // Save pm0 register
    *((char *)0x4) = pm0_saved & 0xFC; // bit 0 and 1 to zero

    cm0_saved = *((char *)0x6); // Save cm0 register
    cm1_saved = *((char *)0x7); // Save cm1 register
    pm1_saved = *((char *)0x5); // Save pm1 register

    // Insert Wait state for all bus access (needed for talking to the
    // internal flash controller)
    asm("BSET	7,0x05"); // Set bit PM17
    CM0.BYTE = 0;
    CM1.BYTE = 0;

  }

  /**
   * Restores the processor mode back to original settings.
   */
  void restoreMCUClock(void)
  {
    *((char *)0x4) = pm0_saved; // Restore pm0 register

    /* Clock settings for R8C and M16C */
    *((char *)0x7) = cm1_saved;   // Restore cm1 register
    *((char *)0x6) = cm0_saved;   // Restore cm0 register
    *((char *)0x5) = pm1_saved;   // Restore pm1 register
    *((char *)0xA) = prcr_saved;  // Protection back on
  }

/**
 * Disable and enable interrups macros. A call to
 * disableInterrupt must be followed by a call to RestoreInterrupt.
 */
#define disableInterrupt() \
    { \
		__nesc_atomic_t flg_saved; \
		asm volatile ("stc flg, %0": "=r"(flg_saved): : "%flg"); \
		asm("fclr i"); \
		asm volatile("" : : : "memory");

#define restoreInterrupt() \
    asm volatile("" : : : "memory"); \
    asm volatile ("ldc %0, flg": : "r"(flg_saved): "%flg"); \
  }

  void clearStatus(unsigned long addr)
  {
    unsigned int low = (unsigned int) addr;
    unsigned int high = (unsigned int)( addr >> 16);

    asm volatile (
        "mov.w #0x0050, r3\n\t"
        "ste.w r3, [a1a0]\n\t"
        :
        : "Ra0"(low), "Ra1"(high)
        : "memory", "r3");
  }

  bool writeWord(unsigned long addr, unsigned int word)
  {
    unsigned int low = (unsigned int) addr;
    unsigned int high = (unsigned int)( addr >> 16);

    asm volatile (
        "mov.w #0x0040, r3\n\t" // Send write command
        "ste.w r3, [a1a0]\n\t"
        "ste.w %[data], [a1a0]\n\t"
        :
        :"Ra0"(low), "Ra1" (high), [data] "r" (word)
        : "memory", "r3");
    return !FMR0.BIT.FMR06;
  }

  command error_t HplM16c60Flash.erase( unsigned char block )
  {
    unsigned int low = (unsigned int) block_addresses[ block ];
    unsigned int high = (unsigned int)( block_addresses[ block ] >> 16);

    // Must change main clock speed to meet flash requirements
    disableInterrupt();
    slowMCUClock();
    FMR0.BIT.FMR01 = 0;
    FMR0.BIT.FMR01 = 1;
    FMR1.BIT.FMR11 = 0;
    FMR1.BIT.FMR11 = 1;
    FMR0.BIT.FMR02 = 0;
    FMR0.BIT.FMR02 = 1;

    asm volatile (
        "mov.w #0x0050, r3\n\t" // Clear status register
        "ste.w r3, [a1a0]\n\t"

        "mov.w #0x0020, r3\n\t" // Block Erase 1(2)
        "ste.w r3, [a1a0]\n\t"

        "mov.w #0x00D0, r3\n\t" // Block Erase 2(2)
        "ste.w r3, [a1a0]\n\t"
        :
        : "Ra0"(low), "Ra1"(high)
        : "memory", "r3");

    // Note: In EW1 Mode, the MCU is suspended until the operation is completed.
    while (!FMR0.BIT.FMR00);
    // Disable CPU rewriting commands by clearing EW entry bit.
    FMR0.BYTE = 0;

    restoreMCUClock(); // Restore clock back to original speed
    restoreInterrupt();
    if( FMR0.BIT.FMR07) // Erasing error?
    {
      return FAIL;  // Erase Fail
    }
    return SUCCESS;  // Erase Pass
  }

  command uint8_t HplM16c60Flash.write( unsigned long flash_addr,
      unsigned int * buffer_addr,
      unsigned int bytes)
  {
    error_t ret_value = SUCCESS;
    unsigned int i;
    // Check for odd number of bytes &c heck for odd address 
    if( bytes & 1 || (int)flash_addr & 1)
      return EINVAL; // ERROR!! You must always pass an even number of bytes.


    disableInterrupt();
    // Must change main clock speed to meet flash requirements
    slowMCUClock();

    FMR0.BIT.FMR01 = 0;
    FMR0.BIT.FMR01 = 1;
    FMR1.BIT.FMR11 = 0;
    FMR1.BIT.FMR11 = 1;
    FMR0.BIT.FMR02 = 0;
    FMR0.BIT.FMR02 = 1;

    // Clear status register
    clearStatus(flash_addr);

    for (i = 0; i < (bytes >> 1); ++i)
    {
      // Write to the flash sequencer by writing to that area of flash memory
      if (!writeWord(flash_addr, buffer_addr[i]))
      {
        uint8_t j;
        bool fail = 1;

        clearStatus(flash_addr);
        for (j = 0; j < 3; ++j)
        {
          if (writeWord(flash_addr, buffer_addr[i]))
          {
            fail = 0;
            break;
          }
        }
        if (fail)
        {
          ret_value = FAIL; // Signal that we had got an error
          break; // Break out of for loop
        }
      }

      flash_addr += 2; // Advance to next flash write address
    }
    // Disable CPU rewriting commands by clearing EW entry bit
    FMR0.BYTE = 0;
    restoreMCUClock(); // Restore clock back to original speed
    restoreInterrupt();
    return ret_value; // Return Pass/Fail
  }

  command uint8_t HplM16c60Flash.read(unsigned long address) {
    unsigned int low = (unsigned int)(address);
    unsigned int high = (unsigned int)(address >> 16);
    unsigned int data;
    disableInterrupt();
    asm volatile (
    	"mov.w #0x00FF, r3\n\t" // Read Array Command, once is enough but to be certain that
    							// a Read Array Command has been executed do it before every
    							// read for now.
        "ste.w r3, [a1a0]\n\t"
        "lde.w [a1a0], %[data]"
        :[data] "=r" (data)
        :"Ra0"(low), "Ra1"(high)
        : "memory", "r3");
    restoreInterrupt();
    return data;
  }
}
