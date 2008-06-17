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
 
#include "tosthread.h"

configuration TosThreadApiC {
}
implementation {
  //Here are all the components that implement the Tosthread API calls
  components CThreadC;
  #if defined(PRINTF_H) || defined(TOSTHREAD_DYNAMIC_LOADER)
    components PrintfC;
  #endif
  #if defined(TOSTHREAD_QUEUE_H) || defined(TOSTHREAD_DYNAMIC_LOADER)
    components CQueueC;
  #endif
  #if defined(TOSTHREAD_LINKED_LIST_H) || defined(TOSTHREAD_DYNAMIC_LOADER)
    components CLinkedListC;
  #endif
  #if defined(TOSTHREAD_THREADSYNC_H) || defined(TOSTHREAD_DYNAMIC_LOADER)
    components CThreadSynchronizationC;
  #endif
  #if defined(TOSTHREAD_LEDS_H) || defined(TOSTHREAD_DYNAMIC_LOADER)
    components CLedsC;
  #endif
  #if defined(TOSTHREAD_AMRADIO_H) || defined(TOSTHREAD_DYNAMIC_LOADER)
    components CAMRadioC;
  #endif
  #if defined(TOSTHREAD_AMSERIAL_H) || defined(TOSTHREAD_DYNAMIC_LOADER)
    components CAMSerialC;
  #endif
  #if defined(TOSTHREAD_BLOCKSTORAGE_H) || defined(TOSTHREAD_DYNAMIC_LOADER)
    components CBlockStorageC;
  #endif 
  #if defined(TOSTHREAD_LOGSTORAGE_H) || defined(TOSTHREAD_DYNAMIC_LOADER)
    components CLogStorageC;
  #endif 
  #if defined(TOSTHREAD_COLLECTION_H) || defined(TOSTHREAD_DYNAMIC_LOADER)
    components CCollectionC;
  #endif 
  
  //Telosb sensorboard specific.
  #if defined(TOSTHREAD_HAMAMATSUS1087_H) || defined(TOSTHREAD_DYNAMIC_LOADER)
    components CHamamatsuS1087ParC;
  #endif
  #if defined(TOSTHREAD_HAMAMATSUS10871_H) || defined(TOSTHREAD_DYNAMIC_LOADER)
    components CHamamatsuS10871TsrC;
  #endif
  #if defined(TOSTHREAD_SENSIRIONSHT11_H) || defined(TOSTHREAD_DYNAMIC_LOADER)
    components CSensirionSht11C;
  #endif
  
  //Universal sensorboard specific
  #if defined(TOSTHREAD_SINESENSOR_H) || defined(TOSTHREAD_DYNAMIC_LOADER)
    components CSineSensorC;
  #endif
  
  //Basicsb sensorboard specific
  #if defined(TOSTHREAD_PHOTO_H) || defined(TOSTHREAD_DYNAMIC_LOADER)
    components CPhotoC;
  #endif
  #if defined(TOSTHREAD_TEMP_H) || defined(TOSTHREAD_DYNAMIC_LOADER)
    components CTempC;
  #endif
}
