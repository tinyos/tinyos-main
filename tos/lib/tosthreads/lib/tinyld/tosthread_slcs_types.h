/*
 * Copyright (c) 2008 Johns Hopkins University.
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
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 */

#ifndef _TOSTHREAD_SLCS_TYPES_H
#define _TOSTHREAD_SLCS_TYPES_H

#include "slcs_types.h"

struct addr fun[] = {
  
  {tosthread_sleep}, {tosthread_create},
    
  {led0On}, {led1On}, {led2On},
  {led0Off}, {led1Off}, {led2Off},
  {led0Toggle}, {led1Toggle}, {led2Toggle},
  
  {amSerialStart}, {amSerialStop}, {amSerialReceive},
  {amSerialSend}, {amSerialLocalAddress}, {amSerialGetLocalGroup},
  {amSerialGetDestination}, {amSerialGetSource}, {amSerialSetDestination},
  {amSerialSetSource}, {amSerialIsForMe}, {amSerialGetType},
  {amSerialSetType}, {amSerialGetGroup}, {amSerialSetGroup},
  {serialClear}, {serialGetPayloadLength}, {serialSetPayloadLength},
  {serialMaxPayloadLength}, {serialGetPayload}, {serialRequestAck},
  {serialNoAck}, {serialWasAcked},
  
  {amRadioStart}, {amRadioStop}, {amRadioReceive},
  {amRadioSend}, {amRadioGetLocalAddress}, {amRadioGetLocalGroup},
  {amRadioGetDestination}, {amRadioGetSource}, {amRadioSetDestination},
  {amRadioSetSource}, {amRadioIsForMe}, {amRadioGetType},
  {amRadioSetType}, {amRadioGetGroup}, {amRadioSetGroup},
  {radioClear}, {radioGetPayloadLength}, {radioSetPayloadLength},
  {radioMaxPayloadLength}, {radioGetPayload}, {radioRequestAck},
  {radioNoAck}, {radioWasAcked},
    
  {semaphore_reset}, {semaphore_acquire}, {semaphore_release},

  {barrier_reset}, {barrier_block}, {barrier_isBlocking},

  {condvar_init}, {condvar_wait}, {condvar_signalNext},
  {condvar_signalAll}, {condvar_isBlocking},

  {mutex_init}, {mutex_lock}, {mutex_unlock},

  {volumeBlockRead}, {volumeBlockWrite}, {volumeBlockCrc},
  {volumeBlockErase}, {volumeBlockSync},

  {refcounter_init}, {refcounter_increment}, {refcounter_decrement},
  {refcounter_waitOnValue}, {refcounter_count},
  
  {amRadioSnoop},

  {queue_init}, {queue_clear}, {queue_enqueue},
  {queue_dequeue}, {queue_remove}, {queue_size},
  {queue_is_empty},

  {sensirionSht11_humidity_read}, {sensirionSht11_humidity_getNumBits}, {sensirionSht11_temperature_read},
  {sensirionSht11_temperature_getNumBits},
  
  {hamamatsuS10871_tsr_read}, {hamamatsuS10871_tsr_readStream}, {hamamatsuS10871_tsr_getNumBits},
  
  {hamamatsuS1087_par_read}, {hamamatsuS1087_par_readStream}, {hamamatsuS1087_par_getNumBits},
  
  {volumeLogRead}, {volumeLogCurrentReadOffset}, {volumeLogSeek},
  {volumeLogGetSize},
  
  {volumeLogAppend}, {volumeLogCurrentWriteOffset}, {volumeLogErase},
  {volumeLogSync},
  
  {getLeds}, {setLeds},

  {div},
  
  {tosthread_join},
  
  {volumeConfigMount}, {volumeConfigRead}, {volumeConfigWrite},
  {volumeConfigCommit}, {volumeConfigGetSize}, {volumeConfigValid}
};

#endif
