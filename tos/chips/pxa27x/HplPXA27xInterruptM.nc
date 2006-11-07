// $Id: HplPXA27xInterruptM.nc,v 1.3 2006-11-07 19:31:10 scipio Exp $ 

/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/*
 *
 * Authors:		Phil Buonadonna
 *
 * Edits:	Josh Herbach
 * Revised: 09/02/2005
 */

module HplPXA27xInterruptM
{
  provides {
    interface HplPXA27xInterrupt as PXA27xIrq[uint8_t id];
    interface HplPXA27xInterruptCntl;
  }
}

implementation 
{

  uint32_t getICHP() {
    uint32_t val;

    asm volatile ("mrc p6,0,%0,c5,c0,0\n\t":"=r" (val));
    return val;
  }

  /* Core PXA27X interrupt dispatch vectors */
  /* DO NOT change the name of these functions */
  void hplarmv_irq() __attribute__ ((interrupt ("IRQ"))) @C() @atomic_hwevent() {

    uint32_t IRQPending;

    IRQPending = getICHP();  // Determine which interrupt to service
    IRQPending >>= 16;  // Right justify to the IRQ portion

    while (IRQPending & (1 << 15)) {
      uint8_t PeripheralID = (IRQPending & 0x3f); // Get rid of the Valid bit
      signal PXA27xIrq.fired[PeripheralID]();     // Handler is responsible for clearing interrupt
      IRQPending = getICHP();  // Determine which interrupt to service
      IRQPending >>= 16;  // Right justify to the IRQ portion
    }

    return;
  }

  void hplarmv_fiq() __attribute__ ((interrupt ("FIQ"))) @C() @atomic_hwevent() {

  } 

  static uint8_t usedPriorities = 0;

  /* Helper functions */
  /* NOTE: Read-back of all register writes is necessary to ensure the data latches */

  error_t allocate(uint8_t id, bool level, uint8_t priority)
  {
    uint32_t tmp;
    error_t error = FAIL;

    atomic{
      uint8_t i;
      if(usedPriorities == 0){//assumed that the table will have some entries
	uint8_t PriorityTable[40], DuplicateTable[40];
	for(i = 0; i < 40; i++){
	  DuplicateTable[i] = PriorityTable[i] = 0xFF;
	}
	
	for(i = 0; i < 40; i++)
	  if(TOSH_IRP_TABLE[i] != 0xff){
	    if(PriorityTable[TOSH_IRP_TABLE[i]] != 0xFF)/*duplicate priorities
							  in the table, mark 
							  for later fixing*/
	      DuplicateTable[i] = PriorityTable[TOSH_IRP_TABLE[i]];
	    else
	      PriorityTable[TOSH_IRP_TABLE[i]] = i;
	  }
	
	//compress table
	for(i = 0; i < 40; i++){
	  if(PriorityTable[i] != 0xff){
	    PriorityTable[usedPriorities] = PriorityTable[i];
	    if(i != usedPriorities)
	      PriorityTable[i] = 0xFF;
	    usedPriorities++;
	  }
	}

	for(i = 0; i < 40; i++)
	  if(DuplicateTable[i] != 0xFF){
	    uint8_t j, ExtraTable[40];
	    for(j = 0; DuplicateTable[i] != PriorityTable[j]; j++);
	    memcpy(ExtraTable + j + 1, PriorityTable + j, usedPriorities - j);
	    memcpy(PriorityTable + j + 1, ExtraTable + j + 1, 
		   usedPriorities - j);
	    PriorityTable[j] = i;
	    usedPriorities++;
	  }

	for(i = 0; i < usedPriorities; i++){
	  IPR(i) = (IPR_VALID | PriorityTable[i]);
	  tmp = IPR(i);
	}
      }

      if (id < 34){
	if(priority == 0xff){
	  priority = usedPriorities;
	  usedPriorities++;
	  IPR(priority) = (IPR_VALID | (id));
	  tmp = IPR(priority);
	}
	if (level) {
	  _ICLR(id) |= _PPID_Bit(id);
	  tmp = _ICLR(id);
	} 
	
	error = SUCCESS;
      }
    }
    return error;
  }
  
  void enable(uint8_t id)
  {
    uint32_t tmp;
    atomic {
      if (id < 34) {
	_ICMR(id) |= _PPID_Bit(id);
	tmp = _ICMR(id);
      }
    }
    return;
  }

  void disable(uint8_t id)
  {
    uint32_t tmp;
    atomic {
      if (id < 34) {
	_ICMR(id) &= ~(_PPID_Bit(id));
	tmp = _ICMR(id);
      }
    }
    return;
  }

  /* Interface implementation */

  async command error_t PXA27xIrq.allocate[uint8_t id]()
  {
    return allocate(id, FALSE, TOSH_IRP_TABLE[id]);
  }

  async command void PXA27xIrq.enable[uint8_t id]()
  {
    enable(id);
    return;
  }

  async command void PXA27xIrq.disable[uint8_t id]()
  {
    disable(id);
    return;
  }

  async command void HplPXA27xInterruptCntl.setICCR_DIM(bool flag) {

    if (flag) {
      ICCR |= ICCR_DIM;
    }
    else {
      ICCR = 0;
    }
    return;

  }

  async command bool HplPXA27xInterruptCntl.getICCR_DIM() {
    bool result = FALSE;

    if (ICCR & ICCR_DIM) {
      result = TRUE;
    }

    return result;
  }

  default async event void PXA27xIrq.fired[uint8_t id]() 
  {
    return;
  }

}
