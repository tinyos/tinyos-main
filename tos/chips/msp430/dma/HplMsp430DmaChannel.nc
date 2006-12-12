/*
 * "Copyright (c) 2000-2005 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * @author Ben Greenstein <ben@cs.ucla.edu>
 * @version $Revision: 1.4 $ $Date: 2006-12-12 18:23:07 $
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
