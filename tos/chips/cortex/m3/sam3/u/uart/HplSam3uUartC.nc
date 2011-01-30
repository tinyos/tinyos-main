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

#include "sam3uuarthardware.h"

/**
 * The hardware presentation layer for the SAM3U UART.
 *
 * @author Wanja Hofer <wanja@cs.fau.de>
 */

configuration HplSam3uUartC {
  provides {
    interface HplSam3uUartConfig;
    interface HplSam3uUartControl;
    interface HplSam3uUartInterrupts;
    interface HplSam3uUartStatus;
  }
#ifdef THREADS
  uses interface PlatformInterrupt;
#endif
}
implementation
{
  components HplSam3uUartP;
  HplSam3uUartConfig = HplSam3uUartP;
  HplSam3uUartControl = HplSam3uUartP;
  HplSam3uUartInterrupts = HplSam3uUartP;
  HplSam3uUartStatus = HplSam3uUartP;
#ifdef THREADS
  PlatformInterrupt = HplSam3uUartP;
#endif

  components McuSleepC;
  HplSam3uUartP.UartInterruptWrapper -> McuSleepC;
}
