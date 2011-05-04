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
 * Hardware interface implementation for the M16c/60 MCU.
 * The interface is responsible of initializing the mcu
 * and rebooting it on request.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */

#include "NetProg_platform.h"

module HardwareC
{
  provides interface Hardware;
}

implementation
{
  command void Hardware.init()
  {
    PRCR.BYTE = BIT1 | BIT0; // Turn off protection for the cpu and clock register

    PM0.BYTE = BIT7;         // Single Chip mode. No BCLK output.
    PM1.BYTE = BIT3;         // Expand internal memory, no global wait state.

    CM0.BYTE = 0x0;          // No sub-clock (Xc) generation
    CM1.BYTE = 0x0;          // CPU_CLOCK = MAIN_CLOCK, low drive on Xin

    PRCR.BYTE = 0;           // Turn on protection on all registers.
  }

  
  command void Hardware.reboot()
  {
    netprog_reboot();
  }
}
