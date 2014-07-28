 /*
 * Copyright (c) 2008 Stanford University.
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

/**
 * @author Kevin Klues <klueska@cs.stanford.edu>
 */
 
#include "printf.h"

configuration PrintfC {}
implementation {
  components MainC;
  components PrintfP;
  PrintfP.Boot -> MainC;

  components new ThreadC(200);
  PrintfP.PrintfThread -> ThreadC;
  
  components BlockingSerialActiveMessageC;
  PrintfP.SerialControl -> BlockingSerialActiveMessageC;
  PrintfP.Packet -> BlockingSerialActiveMessageC;
  
  components new PrintfQueueC(uint8_t, PRINTF_BUFFER_SIZE) as QueueC;
  PrintfP.Queue -> QueueC;
  
  components BarrierC;
  PrintfP.Barrier -> BarrierC;
  
  components MutexC;
  PrintfP.Mutex -> MutexC;

  components new BlockingSerialAMSenderC(AM_PRINTF_MSG);
  PrintfP.BlockingAMSend -> BlockingSerialAMSenderC;

  components LedsC;
  PrintfP.Leds -> LedsC;
}
