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

/**
 * Implementation of the HplM16c60Flash interface. Note that this module
 * should be used with caution so that one doesn't erase the flash where the
 * executing program lies.
 * 
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 * @author Renesas
 */

#include "M16c65Flash.h"
#include "iom16c65.h"

// TODO(henrik) This implementation expects a main clock speed <=10 MHz, fix it.
module HplM16c60FlashC
{
  provides interface HplM16c60Flash;
}
implementation
{

  // Defines an array of highest even addresses for each block
  const unsigned long block_addresses[8] =
  {0xFFFFE,0xEFFFE,0xDFFFE,0xCFFFE,0xBFFFE,0xAFFFE,0x9FFFE,0x8FFFE};

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
    prcr_saved = PRCR.BYTE; // Save Protection register
    PRCR.BYTE = 3; // Allow writting to protected system registers
    // Force to Single chip mode for processors that have memory expansion mode
    pm0_saved = PM0.BYTE; // Save pm0 register
    PM0.BYTE = pm0_saved & 0xFC; // bit 0 and 1 to zero

    cm0_saved = CM0.BYTE; // Save cm0 register
    cm1_saved = CM1.BYTE; // Save cm1 register
    pm1_saved = PM1.BYTE; // Save pm1 register

    // Insert Wait state for all bus access (needed for talking to the
    // internal flash controller)
    PM1.BYTE = PM1.BYTE | 0x80; // Set bit PM17
    //CM0.BYTE = 0;
    //CM1.BYTE = 0;

  }

  /**
   * Restores the processor mode back to original settings.
   */
  void restoreMCUClock(void)
  {
    PM0.BYTE = pm0_saved; // Restore pm0 register

    /* Clock settings for R8C and M16C */
    CM1.BYTE = cm1_saved;   // Restore cm1 register
    CM0.BYTE = cm0_saved;   // Restore cm0 register
    PM1.BYTE = pm1_saved;   // Restore pm1 register
    PRCR.BYTE = prcr_saved;  // Protection back on
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

  bool writeWords(unsigned long addr, unsigned int word, unsigned int word2)
  {
    unsigned int low = (unsigned int) addr;
    unsigned int high = (unsigned int)( addr >> 16);
    unsigned int i = 0;

    for (i = 0; i < 3; ++i)
    {
      asm volatile (
          "mov.w #0x0041, r3\n\t" // Send write command
          "ste.w r3, [a1a0]\n\t"
          "ste.w %[data], [a1a0]\n\t"
          "ste.w %[data2], [a1a0]\n\t"
          :
          :"Ra0"(low), "Ra1" (high), [data] "r" (word), [data2] "r" (word2)
          : "memory", "r3");
      if (!FMR0.BIT.FMR06)
      {
        break;
      }
      clearStatus(addr);
      i++;
    }
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
    FMR6.BYTE = 3;
    FMR1.BIT.FMR11 = 0;
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
    unsigned long flash_addr_start = flash_addr;
    uint8_t* buf = (uint8_t*)buffer_addr;
    // Check for odd number of bytes & check for odd address 
    if( bytes & 0x3 || (int)flash_addr & 0x3)
      return EINVAL; // ERROR!! You must always pass an even number of bytes.


    disableInterrupt();
    // Must change main clock speed to meet flash requirements
    slowMCUClock();

    FMR0.BIT.FMR01 = 0;
    FMR0.BIT.FMR01 = 1;
    FMR1.BIT.FMR11 = 0;
    FMR1.BIT.FMR11 = 1;
    FMR6.BYTE = 3;
    FMR1.BIT.FMR11 = 0;
    FMR0.BIT.FMR02 = 0;
    FMR0.BIT.FMR02 = 1;

    // Clear status register
    clearStatus(flash_addr);

    for (i = 0; i < (bytes >> 1); i += 2)
    {
      // Write to the flash sequencer by writing to that area of flash memory
      // The 65 series writes 4 bytes in each sequence.
      if (!writeWords(flash_addr, buffer_addr[i], buffer_addr[i+1]))
      {
        ret_value = FAIL; // Signal that we had got an error
        break; // Break out of for loop
      }
      flash_addr += 4; // Advance to next flash write address
    }
    // Disable CPU rewriting commands by clearing EW entry bit
    FMR0.BYTE = 0;
    restoreMCUClock(); // Restore clock back to original speed
    restoreInterrupt();

    if (ret_value == SUCCESS)
    {
      // Do a readback to verify the content written
      for (i = 0; i < bytes; ++i)
      {
        if (call HplM16c60Flash.read(flash_addr_start + (unsigned long)i) != buf[i])
        {
          return FAIL;
        }
      }
    }
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
