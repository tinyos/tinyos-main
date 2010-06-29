/*
 * Copyright (c) 2000-2005 The Regents of the University of California.  
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
 * - Neither the name of the copyright holder nor the names of
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
 * @author Ben Greenstein <ben@cs.ucla.edu>
 * @version $Revision: 1.5 $ $Date: 2010-06-29 22:07:45 $
 */

interface HplMsp430DmaChannel {
  async command error_t setTrigger(dma_trigger_t trigger);
  async command void clearTrigger();
  async command void setSingleMode();
  async command void setBlockMode();
  async command void setBurstMode();
  async command void setRepeatedSingleMode();
  async command void setRepeatedBlockMode();
  async command void setRepeatedBurstMode();
  async command void setSrcNoIncrement();
  async command void setSrcDecrement();
  async command void setSrcIncrement();
  async command void setDstNoIncrement();
  async command void setDstDecrement();
  async command void setDstIncrement();
  async command void setWordToWord(); 
  async command void setByteToWord(); 
  async command void setWordToByte(); 
  async command void setByteToByte(); 
  async command void setEdgeSensitive();
  async command void setLevelSensitive();

  async command void enableDMA();
  async command void disableDMA();

  async command void enableInterrupt() ; 
  async command void disableInterrupt() ; 

  async command bool interruptPending();

  async command bool aborted();
  async command void triggerDMA();

  async command void setSrc(void *saddr);
  async command void setDst(void *daddr);
  async command void setSize(uint16_t sz);

  async command void setState(dma_channel_state_t s, dma_channel_trigger_t t, void* src, void* dest, uint16_t size);
  async command void setStateRaw(uint16_t state, uint16_t trigger, void* src, void* dest, uint16_t size);
  async command dma_channel_state_t getState();
  async command void* getSource();
  async command void* getDestination();
  async command uint16_t getSize();
  async command dma_channel_trigger_t getTrigger();

  async command void reset();

  async event void transferDone(error_t success);
}
