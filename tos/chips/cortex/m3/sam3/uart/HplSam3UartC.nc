/*
 * Copyright (c) 2009 Stanford University.
 * All rights reserved.
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
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
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

#include "sam3uarthardware.h"

/**
 * The hardware presentation layer for the SAM3U UART.
 *
 * @author Wanja Hofer <wanja@cs.fau.de>
 */

configuration HplSam3UartC {
  provides {
    interface HplSam3UartConfig;
    interface HplSam3UartControl;
    interface HplSam3UartInterrupts;
    interface HplSam3UartStatus;
  }
#ifdef THREADS
  uses interface PlatformInterrupt;
#endif
}
implementation
{
  components HplSam3UartP;
  HplSam3UartConfig = HplSam3UartP;
  HplSam3UartControl = HplSam3UartP;
  HplSam3UartInterrupts = HplSam3UartP;
  HplSam3UartStatus = HplSam3UartP;
#ifdef THREADS
  PlatformInterrupt = HplSam3UartP;
#endif

  components McuSleepC;
  HplSam3UartP.McuSleep -> McuSleepC;
}
