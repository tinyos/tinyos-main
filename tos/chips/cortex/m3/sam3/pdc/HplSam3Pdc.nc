/*
 * Copyright (c) 2009 Johns Hopkins University.
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
 * - Neither the name of the copyright holders nor the names of its
 *   contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 * WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @author JeongGil Ko
 */

interface HplSam3Pdc {

  /* Pointer Registers */
  async command void setRxPtr(void* addr);
  async command void setTxPtr(void* addr);
  async command void setNextRxPtr(void* addr);
  async command void setNextTxPtr(void* addr);

  async command uint32_t getRxPtr();
  async command uint32_t getTxPtr();
  async command uint32_t getNextRxPtr();
  async command uint32_t getNextTxPtr();

  /* Counter Registers */
  async command void setRxCounter(uint16_t counter);
  async command void setTxCounter(uint16_t counter);
  async command void setNextRxCounter(uint16_t counter);
  async command void setNextTxCounter(uint16_t counter);

  async command uint16_t getRxCounter();
  async command uint16_t getTxCounter();
  async command uint16_t getNextRxCounter();
  async command uint16_t getNextTxCounter();

  /* Enable / Disable Register */
  async command void enablePdcRx();
  async command void enablePdcTx();
  async command void disablePdcRx();
  async command void disablePdcTx();

  /* Status Registers  - Checks status */
  async command bool rxEnabled();
  async command bool txEnabled();

}
