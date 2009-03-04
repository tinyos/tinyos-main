/*
 * Copyright (c) 2008, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.3 $
 * $Date: 2009-03-04 18:31:12 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

#include "TKN154_MAC.h"
#include "TKN154_PHY.h"
interface CC2420Tx {

  async command error_t loadTXFIFO(ieee154_txframe_t *data);
  async event void loadTXFIFODone(ieee154_txframe_t *data, error_t error );

  async command error_t send(bool cca);
  async event void sendDone(ieee154_txframe_t *frame, ieee154_timestamp_t *referenceTime, 
      bool ackPendingFlag, error_t error);

  async command bool cca();
  async command void lockChipSpi();
  async command void unlockChipSpi();  

  async event void transmissionStarted ( ieee154_txframe_t *data );
  async event void transmittedSFD ( uint32_t time, ieee154_txframe_t *data );

  /**
   * Modify the contents of a packet. This command can only be used
   * when an SFD capture event for the sending packet is signalled.
   *
   * @param offset in the message to start modifying.
   * @param buf to data to write
   * @param len of bytes to write
   * @return SUCCESS if the request was accepted, FAIL otherwise.
   */  
  async command error_t modify( uint8_t offset, uint8_t* buf, uint8_t len );

}

