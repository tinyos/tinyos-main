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
 * This module overrides the default SplitControl for the RF230 chip so that
 * the PLL is turned on every time the RF230 chip is turned on.
 * 
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */
module RF230SplitControlP
{
  provides interface SplitControl;
  uses interface SplitControl as SplitControlOrig;
  uses interface SystemClockControl;
}
implementation
{
  command error_t SplitControl.start()
  {
#ifndef RF230_SLOW_SPI
    call SystemClockControl.minSpeed(M16C62P_PLL_CLOCK);
#endif
    return call SplitControlOrig.start();
  }

  event void SplitControlOrig.startDone(error_t error)
  {
#ifndef RF230_SLOW_SPI
    if (error != SUCCESS)
    {
      call SystemClockControl.minSpeed(M16C62P_DONT_CARE);
    }
#endif
    signal SplitControl.startDone(error);
  }

  command error_t SplitControl.stop()
  {
    return call SplitControlOrig.stop();
  }

  event void SplitControlOrig.stopDone(error_t error)
  {
#ifndef RF230_SLOW_SPI
    if (error == SUCCESS)
    {
      call SystemClockControl.minSpeed(M16C62P_DONT_CARE);
    }
#endif
    signal SplitControl.stopDone(error);
  }
}
