/*
 * Copyright (c) 2008 Dimas Abreu Dutra
 * All rights reserved
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
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL DIMAS ABREU
 * DUTRA OR HIS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @author Dimas Abreu Dutra
 */

#include "ApplicationDefinitions.h"
#include "RssiDemoMessages.h"

module SendingMoteC {
  uses interface Boot;
  uses interface Timer<TMilli> as SendTimer;
  
  uses interface AMSend as RssiMsgSend;
  uses interface SplitControl as RadioControl;
} implementation {
  message_t msg;
  
  event void Boot.booted(){
    call RadioControl.start();
  }

  event void RadioControl.startDone(error_t result){
    call SendTimer.startPeriodic(SEND_INTERVAL_MS);
  }

  event void RadioControl.stopDone(error_t result){}


  event void SendTimer.fired(){
    call RssiMsgSend.send(AM_BROADCAST_ADDR, &msg, sizeof(RssiMsg));    
  }

  event void RssiMsgSend.sendDone(message_t *m, error_t error){}
}
