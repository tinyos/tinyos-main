/*
 * Copyright (c) 2006 Arch Rock Corporation
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
 * - Neither the name of the Arch Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 *
 */

/**
 * The DisseminatorP module holds and synchronizes a single value of a
 * chosen type.
 *
 * See TEP118 - Dissemination for details.
 * 
 * @param t the type of the object that will be disseminated
 *
 * @author Gilman Tolle <gtolle@archrock.com>
 * @version $Revision: 1.1 $ $Date: 2007-12-18 07:03:19 $
 */

generic module DisseminatorP(typedef t, dip_key_t key) {
  provides interface DisseminationValue<t> as AppDisseminationValue;
  provides interface DisseminationUpdate<t> as AppDisseminationUpdate;
  provides interface DisseminationUpdate<dip_data_t> as DataDisseminationUpdate;
  provides interface DisseminationValue<dip_data_t> as DataDisseminationValue;

  provides interface Init;

  uses interface DisseminationUpdate<dip_data_t> as DIPDisseminationUpdate;
  uses interface DIPHelp;

  uses interface Leds;
}
implementation {
  dip_data_t valueCache;

  task void signalNewData() {
    signal AppDisseminationValue.changed();
  }

  command error_t Init.init() {
    call DIPHelp.registerKey(key);
    return SUCCESS;
  }

  // A sequence number is 32 bits. The top 16 bits are an incrementing
  // counter, while the bottom 16 bits are a unique node identifier.
  // But versions aren't stored here.

  command const t* AppDisseminationValue.get() {
    return (t*) &valueCache;
  }

  command void AppDisseminationValue.set( const t* val ) {
    memcpy( &valueCache, val, sizeof(t) );
  }

  command void AppDisseminationUpdate.change( t* newVal ) {
    memcpy( &valueCache, newVal, sizeof(t) );
    /* Increment the counter and append the local node ID later. */
    /* DIPLogicC doesn't care what the data actually is,
       it just wants the key, so we cast it recklessly */
    call DIPDisseminationUpdate.change((dip_data_t*)newVal);
  }

  command const dip_data_t* DataDisseminationValue.get() {
    return (dip_data_t*) &valueCache;
  }

  command void DataDisseminationValue.set( const dip_data_t* val ) {  }

  command void DataDisseminationUpdate.change( dip_data_t* newVal ) {
    memcpy( &valueCache, newVal, sizeof(dip_data_t) );
    //post signalNewData();
    signal AppDisseminationValue.changed();
  }


  default event void AppDisseminationValue.changed() { }

  default event void DataDisseminationValue.changed() { }

}
