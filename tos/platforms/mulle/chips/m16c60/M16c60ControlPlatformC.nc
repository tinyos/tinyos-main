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

/**
 * Mulle specific implementation of the M16c60ControlPlatform interface.
 * 
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */
module M16c60ControlPlatformC
{
  provides interface M16c60ControlPlatform;
}
implementation
{
  async command void M16c60ControlPlatform.PLLOn()
  {
    // Set all timers that uses the main clock
    // as source to use F2 instead of F1 because
    // the main clock will be twice as fast when PLL
    // is on.
    // Set the UARTS clock source to F2 instead of F1.

    // NOTE: No need to turn on/off protections for registers,
    // this is handeled by the caller of this code.
    CLR_BIT(PCLKR.BYTE, 0); // Timers
    CLR_BIT(PCLKR.BYTE, 1); // Uarts
  }

  async command void M16c60ControlPlatform.PLLOff()
  {
    // Restore settings done in PLLOn()
    // NOTE: No need to turn on/off protections for registers,
    // this is handeled by the caller of this code.
    SET_BIT(PCLKR.BYTE, 0);
    SET_BIT(PCLKR.BYTE, 1);
  }
}
