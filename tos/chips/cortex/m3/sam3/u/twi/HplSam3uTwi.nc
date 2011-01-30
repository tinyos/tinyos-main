/*
 * Copyright (c) 2009 Johns Hopkins University.
 * Copyright (c) 2010 CSIRO Australia
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

// This file shows the Hpl level commands.
#include <sam3utwihardware.h>

interface HplSam3uTwi{

  async command void init();
  async command void enableClock();
  async command void disableClock();
  async command void configureTwi(const sam3u_twi_union_config_t* config);

  /*Control Register Functions*/
  async command void setStart();
  async command void setStop();
  async command void setMaster();
  async command void disMaster();
  async command void setSlave();
  async command void disSlave();
  async command void setQuick();
  async command void swReset();

  /*Master Mode Register Functions*/
  async command void setDeviceAddr(uint8_t dadr);
  async command void setDirection(uint8_t mread);
  async command void addrSize(uint8_t iadrsz);

  /*Slave Mode Register Functions*/
  async command void setSlaveAddr(uint8_t sadr);

  /*Internal Addr Register Functions*/
  async command void setInternalAddr(uint32_t iadr);

  /*Clock Waveform Generator Register Functions*/
  async command void setClockLowDiv(uint8_t cldiv);
  async command void setClockHighDiv(uint8_t chdiv);
  async command void setClockDiv(uint8_t ckdiv);

  /*Status Register Functions*/
  async command twi_sr_t getStatus();
  async command uint8_t getTxCompleted(twi_sr_t *sr);
  async command uint8_t getRxReady(twi_sr_t *sr);
  async command uint8_t getTxReady(twi_sr_t *sr);
  async command uint8_t getSlaveRead(twi_sr_t *sr);
  async command uint8_t getSlaveAccess(twi_sr_t *sr);
  async command uint8_t getGenCallAccess(twi_sr_t *sr);
  async command uint8_t getORErr(twi_sr_t *sr);
  async command uint8_t getNack(twi_sr_t *sr);
  async command uint8_t getArbLost(twi_sr_t *sr);
  async command uint8_t getClockWaitState(twi_sr_t *sr);
  async command uint8_t getEOSAccess(twi_sr_t *sr);
  async command uint8_t getEndRx(twi_sr_t *sr);
  async command uint8_t getEndTx(twi_sr_t *sr);
  async command uint8_t getRxBufFull(twi_sr_t *sr);
  async command uint8_t getTxBufEmpty(twi_sr_t *sr);

  /*Interrupt Enable Register Functions*/
  async command void setIntTxComp();
  async command void setIntRxReady();
  async command void setIntTxReady();
  async command void setIntSlaveAccess();
  async command void setIntGenCallAccess();
  async command void setIntORErr();
  async command void setIntNack();
  async command void setIntArbLost();
  async command void setIntClockWaitState();
  async command void setIntEOSAccess();
  async command void setIntEndRx();
  async command void setIntEndTx();
  async command void setIntRxBufFull();
  async command void setIntTxBufEmpty();

  /*Interrupt Disable Register*/
  async command void disableAllInterrupts();
  async command void disIntTxComp();
  async command void disIntRxReady();
  async command void disIntTxReady();
  async command void disIntSlaveAccess();
  async command void disIntGenCallAccess();
  async command void disIntORErr();
  async command void disIntNack();
  async command void disIntArbLost();
  async command void disIntClockWaitState();
  async command void disIntEOSAccess();
  async command void disIntEndRx();
  async command void disIntEndTx();
  async command void disIntRxBufFull();
  async command void disIntTxBufEmpty();

  /*Interrupt Mask Register*/
  async command uint8_t maskIntTxComp();
  async command uint8_t maskIntRxReady();
  async command uint8_t maskIntTxReady();
  async command uint8_t maskIntSlaveAccess();
  async command uint8_t maskIntGenCallAccess();
  async command uint8_t maskIntORErr();
  async command uint8_t maskIntNack();
  async command uint8_t maskIntArbLost();
  async command uint8_t maskIntClockWaitState();
  async command uint8_t maskIntEOSAccess();
  async command uint8_t maskIntEndRx();
  async command uint8_t maskIntEndTx();
  async command uint8_t maskIntRxBufFull();
  async command uint8_t maskIntTxBufEmpty();

  /*Receive Holding Register Function*/
  async command uint8_t readRxReg();

  /*Transmit Holding Register Functions*/
  async command void setTxReg(uint8_t buffer);
}
