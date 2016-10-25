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

#include "sam3utwihardware.h"
module HplSam3uTwiImplP {
  provides {
    interface HplSam3uTwi as HplSam3uTwi0;
    interface HplSam3uTwi as HplSam3uTwi1;
    interface HplSam3uTwiInterrupt as Interrupt0;
    interface HplSam3uTwiInterrupt as Interrupt1;
  }
  uses {
    interface HplNVICInterruptCntl as Twi0Interrupt;
    interface HplNVICInterruptCntl as Twi1Interrupt;
    interface HplSam3GeneralIOPin as Twd0Pin;
    interface HplSam3GeneralIOPin as Twd1Pin;
    interface HplSam3GeneralIOPin as Twck0Pin;
    interface HplSam3GeneralIOPin as Twck1Pin;
    interface HplSam3PeripheralClockCntl as Twi0ClockControl;
    interface HplSam3PeripheralClockCntl as Twi1ClockControl;
    interface HplSam3Clock as Twi0ClockConfig;
    interface HplSam3Clock as Twi1ClockConfig;
    interface McuSleep;
    interface Leds;
  }
}
implementation{

  void Twi0IrqHandler() @C() @spontaneous() {
    call McuSleep.irq_preamble();
    signal Interrupt0.fired();
    call McuSleep.irq_postamble();
  }

  void Twi1IrqHandler() @C() @spontaneous() {
    call McuSleep.irq_preamble();
    signal Interrupt1.fired();
    call McuSleep.irq_postamble();
  }

  async command void HplSam3uTwi0.disableAllInterrupts() {
    call HplSam3uTwi0.disIntTxComp();
    call HplSam3uTwi0.disIntRxReady();
    call HplSam3uTwi0.disIntTxReady();
    call HplSam3uTwi0.disIntSlaveAccess();
    call HplSam3uTwi0.disIntGenCallAccess();
    call HplSam3uTwi0.disIntORErr();
    call HplSam3uTwi0.disIntNack();
    call HplSam3uTwi0.disIntArbLost();
    call HplSam3uTwi0.disIntClockWaitState();
    call HplSam3uTwi0.disIntEOSAccess();
    call HplSam3uTwi0.disIntEndRx();
    call HplSam3uTwi0.disIntEndTx();
    call HplSam3uTwi0.disIntRxBufFull();
    call HplSam3uTwi0.disIntTxBufEmpty();
  }
  async command void HplSam3uTwi1.disableAllInterrupts() {
    call HplSam3uTwi1.disIntTxComp();
    call HplSam3uTwi1.disIntRxReady();
    call HplSam3uTwi1.disIntTxReady();
    call HplSam3uTwi1.disIntSlaveAccess();
    call HplSam3uTwi1.disIntGenCallAccess();
    call HplSam3uTwi1.disIntORErr();
    call HplSam3uTwi1.disIntNack();
    call HplSam3uTwi1.disIntArbLost();
    call HplSam3uTwi1.disIntClockWaitState();
    call HplSam3uTwi1.disIntEOSAccess();
    call HplSam3uTwi1.disIntEndRx();
    call HplSam3uTwi1.disIntEndTx();
    call HplSam3uTwi1.disIntRxBufFull();
    call HplSam3uTwi1.disIntTxBufEmpty();
  }

  async command void HplSam3uTwi0.configureTwi(const sam3u_twi_union_config_t *config){

    call Twi0Interrupt.configure(IRQ_PRIO_TWI0);
    call Twi0Interrupt.enable();

    call Twi0ClockControl.enable();

    call Twd0Pin.disablePioControl();
    call Twd0Pin.selectPeripheralA();
    call Twck0Pin.disablePioControl();
    call Twck0Pin.selectPeripheralA();

    call HplSam3uTwi0.setClockLowDiv((uint8_t)config->cldiv);
    call HplSam3uTwi0.setClockHighDiv((uint8_t)config->chdiv);
    call HplSam3uTwi0.setClockDiv((uint8_t)config->ckdiv);

    call HplSam3uTwi0.disableAllInterrupts();
  }

  async command void HplSam3uTwi0.disableClock(){
    call Twi0ClockControl.disable();
  }

  async command void HplSam3uTwi1.disableClock(){
    call Twi1ClockControl.disable();
  }

  async command void HplSam3uTwi0.enableClock(){
    call Twi0ClockControl.enable();
  }

  async command void HplSam3uTwi1.enableClock(){
    call Twi1ClockControl.enable();
  }

  async command void HplSam3uTwi1.configureTwi(const sam3u_twi_union_config_t *config){

    call Twi1Interrupt.configure(IRQ_PRIO_TWI1);
    call Twi1Interrupt.enable();

    call Twi1ClockControl.enable();

    call Twd1Pin.disablePioControl();
    call Twd1Pin.selectPeripheralA();
    call Twck1Pin.disablePioControl();
    call Twck1Pin.selectPeripheralA();

    call HplSam3uTwi1.setClockLowDiv((uint8_t)config->cldiv);
    call HplSam3uTwi1.setClockHighDiv((uint8_t)config->chdiv);
    call HplSam3uTwi1.setClockDiv((uint8_t)config->ckdiv);

    call HplSam3uTwi1.disableAllInterrupts();
  }

  async command void HplSam3uTwi0.init(){
    call HplSam3uTwi0.disableAllInterrupts();
  }

  async command void HplSam3uTwi1.init(){
    call HplSam3uTwi1.disableAllInterrupts();
  }

  async command void HplSam3uTwi0.setStart(){
    volatile twi_cr_t* CR = (volatile twi_cr_t *) (TWI0_BASE_ADDR + 0x0);
    twi_cr_t cr;
    cr.bits.start = 1;
    *CR = cr;
  }

  async command void HplSam3uTwi0.setStop(){
    volatile twi_cr_t* CR = (volatile twi_cr_t *) (TWI0_BASE_ADDR + 0x0);
    twi_cr_t cr;
    cr.bits.stop = 1;
    *CR = cr;
  }

  async command void HplSam3uTwi1.setStart(){
    volatile twi_cr_t* CR = (volatile twi_cr_t *) (TWI1_BASE_ADDR + 0x0);
    twi_cr_t cr;
    cr.bits.start = 1;
    *CR = cr;
  }

  async command void HplSam3uTwi1.setStop(){
    volatile twi_cr_t* CR = (volatile twi_cr_t *) (TWI1_BASE_ADDR + 0x0);
    twi_cr_t cr;
    cr.bits.stop = 1;
    *CR = cr;
  }

  async command void HplSam3uTwi0.setMaster(){
    volatile twi_cr_t* CR = (volatile twi_cr_t *) (TWI0_BASE_ADDR + 0x0);
    twi_cr_t cr;
    cr.bits.msen = 1;
    *CR = cr;
  }

  async command void HplSam3uTwi0.disMaster(){
    volatile twi_cr_t* CR = (volatile twi_cr_t *) (TWI0_BASE_ADDR + 0x0);
    twi_cr_t cr;
    cr.bits.msdis = 1;
    *CR = cr;
  }

  async command void HplSam3uTwi1.setMaster(){
    volatile twi_cr_t* CR = (volatile twi_cr_t *) (TWI1_BASE_ADDR + 0x0);
    twi_cr_t cr;
    cr.bits.msen = 1;
    *CR = cr;
  }

  async command void HplSam3uTwi1.disMaster(){
    volatile twi_cr_t* CR = (volatile twi_cr_t *) (TWI1_BASE_ADDR + 0x0);
    twi_cr_t cr;
    cr.bits.msdis = 1;
    *CR = cr;
  }

  async command void HplSam3uTwi0.setSlave(){
    volatile twi_cr_t* CR = (volatile twi_cr_t *) (TWI0_BASE_ADDR + 0x0);
    twi_cr_t cr;
    cr.bits.sven = 1;
    *CR = cr;
  }

  async command void HplSam3uTwi0.disSlave(){
    volatile twi_cr_t* CR = (volatile twi_cr_t *) (TWI0_BASE_ADDR + 0x0);
    twi_cr_t cr;
    cr.bits.svdis = 1;
    *CR = cr;
  }

  async command void HplSam3uTwi1.setSlave(){
    volatile twi_cr_t* CR = (volatile twi_cr_t *) (TWI1_BASE_ADDR + 0x0);
    twi_cr_t cr;
    cr.bits.sven = 1;
    *CR = cr;
  }

  async command void HplSam3uTwi1.disSlave(){
    volatile twi_cr_t* CR = (volatile twi_cr_t *) (TWI1_BASE_ADDR + 0x0);
    twi_cr_t cr;
    cr.bits.svdis = 1;
    *CR = cr;
  }

  async command void HplSam3uTwi0.setQuick(){
    volatile twi_cr_t* CR = (volatile twi_cr_t *) (TWI0_BASE_ADDR + 0x0);
    twi_cr_t cr;
    cr.bits.quick = 1;
    *CR = cr;
  }

  async command void HplSam3uTwi1.setQuick(){
    volatile twi_cr_t* CR = (volatile twi_cr_t *) (TWI1_BASE_ADDR + 0x0);
    twi_cr_t cr;
    cr.bits.quick = 1;
    *CR = cr;
  }

  async command void HplSam3uTwi0.swReset(){
    volatile twi_cr_t* CR = (volatile twi_cr_t *) (TWI0_BASE_ADDR + 0x0);
    twi_cr_t cr;
    cr.bits.swrst = 1;
    *CR = cr;
  }

  async command void HplSam3uTwi1.swReset(){
    volatile twi_cr_t* CR = (volatile twi_cr_t *) (TWI1_BASE_ADDR + 0x0);
    twi_cr_t cr;
    cr.bits.swrst = 1;
    *CR = cr;
  }

  async command void HplSam3uTwi0.setDeviceAddr(uint8_t dadr){
    volatile twi_mmr_t* MMR = (volatile twi_mmr_t *) (TWI0_BASE_ADDR + 0x4);
    twi_mmr_t mmr = *MMR;
    mmr.bits.dadr = dadr;
    *MMR = mmr;
  }
  async command void HplSam3uTwi1.setDeviceAddr(uint8_t dadr){
    volatile twi_mmr_t* MMR = (volatile twi_mmr_t *) (TWI1_BASE_ADDR + 0x4);
    twi_mmr_t mmr = *MMR;
    mmr.bits.dadr = dadr;
    *MMR = mmr;
  }
  async command void HplSam3uTwi0.setDirection(uint8_t mread){
    volatile twi_mmr_t* MMR = (volatile twi_mmr_t *) (TWI0_BASE_ADDR + 0x4);
    twi_mmr_t mmr = *MMR;
    mmr.bits.mread = mread;
    *MMR = mmr;
  }
  async command void HplSam3uTwi1.setDirection(uint8_t mread){
    volatile twi_mmr_t* MMR = (volatile twi_mmr_t *) (TWI1_BASE_ADDR + 0x4);
    twi_mmr_t mmr = *MMR;
    mmr.bits.mread = mread;
    *MMR = mmr;
  }
  async command void HplSam3uTwi0.addrSize(uint8_t iadrsz){
    volatile twi_mmr_t* MMR = (volatile twi_mmr_t *) (TWI0_BASE_ADDR + 0x4);
    twi_mmr_t mmr = *MMR;
    mmr.bits.iadrsz = iadrsz;
    *MMR = mmr;
  }
  async command void HplSam3uTwi1.addrSize(uint8_t iadrsz){
    volatile twi_mmr_t* MMR = (volatile twi_mmr_t *) (TWI1_BASE_ADDR + 0x4);
    twi_mmr_t mmr = *MMR;
    mmr.bits.iadrsz = iadrsz;
    *MMR = mmr;
  }

  async command void HplSam3uTwi0.setSlaveAddr(uint8_t sadr){
    volatile twi_smr_t* SMR = (volatile twi_smr_t *) (TWI0_BASE_ADDR + 0x8);
    twi_smr_t smr = *SMR;
    smr.bits.sadr = sadr;
    *SMR = smr;
  }
  async command void HplSam3uTwi1.setSlaveAddr(uint8_t sadr){
    volatile twi_smr_t* SMR = (volatile twi_smr_t *) (TWI1_BASE_ADDR + 0x8);
    twi_smr_t smr = *SMR;
    smr.bits.sadr = sadr;
    *SMR = smr;
  }

  async command void HplSam3uTwi0.setInternalAddr(uint32_t iadr){
    volatile twi_iadr_t* IADR = (volatile twi_iadr_t *) (TWI0_BASE_ADDR + 0xC);
    twi_iadr_t iadr_r = *IADR;
    iadr_r.bits.iadr = iadr;
    *IADR = iadr_r;
  }
  async command void HplSam3uTwi1.setInternalAddr(uint32_t iadr){
    volatile twi_iadr_t* IADR = (volatile twi_iadr_t *) (TWI1_BASE_ADDR + 0xC);
    twi_iadr_t iadr_r = *IADR;
    iadr_r.bits.iadr = iadr;
    *IADR = iadr_r;
  }

  async command void HplSam3uTwi0.setClockLowDiv(uint8_t cldiv){
    volatile twi_cwgr_t* CWGR = (volatile twi_cwgr_t *) (TWI0_BASE_ADDR + 0x10);
    twi_cwgr_t cwgr = *CWGR;
    cwgr.bits.cldiv = cldiv;
    *CWGR = cwgr;
  }
  async command void HplSam3uTwi1.setClockLowDiv(uint8_t cldiv){
    volatile twi_cwgr_t* CWGR = (volatile twi_cwgr_t *) (TWI1_BASE_ADDR + 0x10);
    twi_cwgr_t cwgr = *CWGR;
    cwgr.bits.cldiv = cldiv;
    *CWGR = cwgr;
  }
  async command void HplSam3uTwi0.setClockHighDiv(uint8_t chdiv){
    volatile twi_cwgr_t* CWGR = (volatile twi_cwgr_t *) (TWI0_BASE_ADDR + 0x10);
    twi_cwgr_t cwgr = *CWGR;
    cwgr.bits.chdiv = chdiv;
    *CWGR = cwgr;
  }
  async command void HplSam3uTwi1.setClockHighDiv(uint8_t chdiv){
    volatile twi_cwgr_t* CWGR = (volatile twi_cwgr_t *) (TWI1_BASE_ADDR + 0x10);
    twi_cwgr_t cwgr = *CWGR;
    cwgr.bits.chdiv = chdiv;
    *CWGR = cwgr;
  }
  async command void HplSam3uTwi0.setClockDiv(uint8_t ckdiv){
    volatile twi_cwgr_t* CWGR = (volatile twi_cwgr_t *) (TWI0_BASE_ADDR + 0x10);
    twi_cwgr_t cwgr = *CWGR;
    cwgr.bits.ckdiv = ckdiv;
    *CWGR = cwgr;
  }
  async command void HplSam3uTwi1.setClockDiv(uint8_t ckdiv){
    volatile twi_cwgr_t* CWGR = (volatile twi_cwgr_t *) (TWI1_BASE_ADDR + 0x10);
    twi_cwgr_t cwgr = *CWGR;
    cwgr.bits.ckdiv = ckdiv;
    *CWGR = cwgr;
  }

  async command twi_sr_t HplSam3uTwi0.getStatus() {
    return TWI0->sr;
  }
  async command uint8_t HplSam3uTwi0.getTxCompleted(twi_sr_t *sr){
    return sr->bits.txcomp;
  }
  async command uint8_t HplSam3uTwi0.getRxReady(twi_sr_t *sr){
    return sr->bits.rxrdy;
  }
  async command uint8_t HplSam3uTwi0.getTxReady(twi_sr_t *sr){
    return sr->bits.txrdy;
  }
  async command uint8_t HplSam3uTwi0.getSlaveRead(twi_sr_t *sr){
    return sr->bits.svread;
  }
  async command uint8_t HplSam3uTwi0.getSlaveAccess(twi_sr_t *sr){
    return sr->bits.svacc;
  }
  async command uint8_t HplSam3uTwi0.getGenCallAccess(twi_sr_t *sr){
    return sr->bits.gacc;
  }
  async command uint8_t HplSam3uTwi0.getORErr(twi_sr_t *sr){
    return sr->bits.ovre;
  }
  async command uint8_t HplSam3uTwi0.getNack(twi_sr_t *sr){
    return sr->bits.nack;
  }
  async command uint8_t HplSam3uTwi0.getArbLost(twi_sr_t *sr){
    return sr->bits.arblst;
  }
  async command uint8_t HplSam3uTwi0.getClockWaitState(twi_sr_t *sr){
    return sr->bits.sclws;
  }
  async command uint8_t HplSam3uTwi0.getEOSAccess(twi_sr_t *sr){
    return sr->bits.eosacc;
  }
  async command uint8_t HplSam3uTwi0.getEndRx(twi_sr_t *sr){
    return sr->bits.endrx;
  }
  async command uint8_t HplSam3uTwi0.getEndTx(twi_sr_t *sr){
    return sr->bits.endtx;
  }
  async command uint8_t HplSam3uTwi0.getRxBufFull(twi_sr_t *sr){
    return sr->bits.rxbuff;
  }
  async command uint8_t HplSam3uTwi0.getTxBufEmpty(twi_sr_t *sr){
    return sr->bits.txbufe;
  }

  async command twi_sr_t HplSam3uTwi1.getStatus() {
    return TWI1->sr;
  }
  async command uint8_t HplSam3uTwi1.getTxCompleted(twi_sr_t *sr){
    return sr->bits.txcomp;
  }
  async command uint8_t HplSam3uTwi1.getRxReady(twi_sr_t *sr){
    return sr->bits.rxrdy;
  }
  async command uint8_t HplSam3uTwi1.getTxReady(twi_sr_t *sr){
    return sr->bits.txrdy;
  }
  async command uint8_t HplSam3uTwi1.getSlaveRead(twi_sr_t *sr){
    return sr->bits.svread;
  }
  async command uint8_t HplSam3uTwi1.getSlaveAccess(twi_sr_t *sr){
    return sr->bits.svacc;
  }
  async command uint8_t HplSam3uTwi1.getGenCallAccess(twi_sr_t *sr){
    return sr->bits.gacc;
  }
  async command uint8_t HplSam3uTwi1.getORErr(twi_sr_t *sr){
    return sr->bits.ovre;
  }
  async command uint8_t HplSam3uTwi1.getNack(twi_sr_t *sr){
    return sr->bits.nack;
  }
  async command uint8_t HplSam3uTwi1.getArbLost(twi_sr_t *sr){
    return sr->bits.arblst;
  }
  async command uint8_t HplSam3uTwi1.getClockWaitState(twi_sr_t *sr){
    return sr->bits.sclws;
  }
  async command uint8_t HplSam3uTwi1.getEOSAccess(twi_sr_t *sr){
    return sr->bits.eosacc;
  }
  async command uint8_t HplSam3uTwi1.getEndRx(twi_sr_t *sr){
    return sr->bits.endrx;
  }
  async command uint8_t HplSam3uTwi1.getEndTx(twi_sr_t *sr){
    return sr->bits.endtx;
  }
  async command uint8_t HplSam3uTwi1.getRxBufFull(twi_sr_t *sr){
    return sr->bits.rxbuff;
  }
  async command uint8_t HplSam3uTwi1.getTxBufEmpty(twi_sr_t *sr){
    return sr->bits.txbufe;
  }

  async command void HplSam3uTwi0.setIntTxComp(){
    volatile twi_ier_t* IER = (volatile twi_ier_t *) (TWI0_BASE_ADDR + 0x24);
    twi_ier_t ier;
    ier.bits.txcomp = 1;
    *IER = ier;
  }
  async command void HplSam3uTwi0.setIntRxReady(){
    volatile twi_ier_t* IER = (volatile twi_ier_t *) (TWI0_BASE_ADDR + 0x24);
    twi_ier_t ier;
    ier.bits.rxrdy = 1;
    *IER = ier;
  }
  async command void HplSam3uTwi0.setIntTxReady(){
    volatile twi_ier_t* IER = (volatile twi_ier_t *) (TWI0_BASE_ADDR + 0x24);
    twi_ier_t ier;
    ier.bits.txrdy = 1;
    *IER = ier;
  }
  async command void HplSam3uTwi0.setIntSlaveAccess(){
    volatile twi_ier_t* IER = (volatile twi_ier_t *) (TWI0_BASE_ADDR + 0x24);
    twi_ier_t ier;
    ier.bits.svacc = 1;
    *IER = ier;
  }
  async command void HplSam3uTwi0.setIntGenCallAccess(){
    volatile twi_ier_t* IER = (volatile twi_ier_t *) (TWI0_BASE_ADDR + 0x24);
    twi_ier_t ier;
    ier.bits.gacc = 1;
    *IER = ier;
  }
  async command void HplSam3uTwi0.setIntORErr(){
    volatile twi_ier_t* IER = (volatile twi_ier_t *) (TWI0_BASE_ADDR + 0x24);
    twi_ier_t ier;
    ier.bits.ovre = 1;
    *IER = ier;
  }
  async command void HplSam3uTwi0.setIntNack(){
    volatile twi_ier_t* IER = (volatile twi_ier_t *) (TWI0_BASE_ADDR + 0x24);
    twi_ier_t ier;
    ier.bits.nack = 1;
    *IER = ier;
  }
  async command void HplSam3uTwi0.setIntArbLost(){
    volatile twi_ier_t* IER = (volatile twi_ier_t *) (TWI0_BASE_ADDR + 0x24);
    twi_ier_t ier;
    ier.bits.arblst = 1;
    *IER = ier;
  }
  async command void HplSam3uTwi0.setIntClockWaitState(){
    volatile twi_ier_t* IER = (volatile twi_ier_t *) (TWI0_BASE_ADDR + 0x24);
    twi_ier_t ier;
    ier.bits.sclws = 1;
    *IER = ier;
  }
  async command void HplSam3uTwi0.setIntEOSAccess(){
    volatile twi_ier_t* IER = (volatile twi_ier_t *) (TWI0_BASE_ADDR + 0x24);
    twi_ier_t ier;
    ier.bits.eosacc = 1;
    *IER = ier;
  }
  async command void HplSam3uTwi0.setIntEndRx(){
    volatile twi_ier_t* IER = (volatile twi_ier_t *) (TWI0_BASE_ADDR + 0x24);
    twi_ier_t ier;
    ier.bits.endrx = 1;
    *IER = ier;
  }
  async command void HplSam3uTwi0.setIntEndTx(){
    volatile twi_ier_t* IER = (volatile twi_ier_t *) (TWI0_BASE_ADDR + 0x24);
    twi_ier_t ier;
    ier.bits.endtx = 1;
    *IER = ier;
  }
  async command void HplSam3uTwi0.setIntRxBufFull(){
    volatile twi_ier_t* IER = (volatile twi_ier_t *) (TWI0_BASE_ADDR + 0x24);
    twi_ier_t ier;
    ier.bits.rxbuff = 1;
    *IER = ier;
  }
  async command void HplSam3uTwi0.setIntTxBufEmpty(){
    volatile twi_ier_t* IER = (volatile twi_ier_t *) (TWI0_BASE_ADDR + 0x24);
    twi_ier_t ier;
    ier.bits.txbufe = 1;
    *IER = ier;
  }
  async command void HplSam3uTwi1.setIntTxComp(){
    volatile twi_ier_t* IER = (volatile twi_ier_t *) (TWI1_BASE_ADDR + 0x24);
    twi_ier_t ier;
    ier.bits.txcomp = 1;
    *IER = ier;
  }
  async command void HplSam3uTwi1.setIntRxReady(){
    volatile twi_ier_t* IER = (volatile twi_ier_t *) (TWI1_BASE_ADDR + 0x24);
    twi_ier_t ier;
    ier.bits.rxrdy = 1;
    *IER = ier;
  }
  async command void HplSam3uTwi1.setIntTxReady(){
    volatile twi_ier_t* IER = (volatile twi_ier_t *) (TWI1_BASE_ADDR + 0x24);
    twi_ier_t ier;
    ier.bits.txrdy = 1;
    *IER = ier;
  }
  async command void HplSam3uTwi1.setIntSlaveAccess(){
    volatile twi_ier_t* IER = (volatile twi_ier_t *) (TWI1_BASE_ADDR + 0x24);
    twi_ier_t ier;
    ier.bits.svacc = 1;
    *IER = ier;
  }
  async command void HplSam3uTwi1.setIntGenCallAccess(){
    volatile twi_ier_t* IER = (volatile twi_ier_t *) (TWI1_BASE_ADDR + 0x24);
    twi_ier_t ier;
    ier.bits.gacc = 1;
    *IER = ier;
  }
  async command void HplSam3uTwi1.setIntORErr(){
    volatile twi_ier_t* IER = (volatile twi_ier_t *) (TWI1_BASE_ADDR + 0x24);
    twi_ier_t ier;
    ier.bits.ovre = 1;
    *IER = ier;
  }
  async command void HplSam3uTwi1.setIntNack(){
    volatile twi_ier_t* IER = (volatile twi_ier_t *) (TWI1_BASE_ADDR + 0x24);
    twi_ier_t ier;
    ier.bits.nack = 1;
    *IER = ier;
  }
  async command void HplSam3uTwi1.setIntArbLost(){
    volatile twi_ier_t* IER = (volatile twi_ier_t *) (TWI1_BASE_ADDR + 0x24);
    twi_ier_t ier;
    ier.bits.arblst = 1;
    *IER = ier;
  }
  async command void HplSam3uTwi1.setIntClockWaitState(){
    volatile twi_ier_t* IER = (volatile twi_ier_t *) (TWI1_BASE_ADDR + 0x24);
    twi_ier_t ier;
    ier.bits.sclws = 1;
    *IER = ier;
  }
  async command void HplSam3uTwi1.setIntEOSAccess(){
    volatile twi_ier_t* IER = (volatile twi_ier_t *) (TWI1_BASE_ADDR + 0x24);
    twi_ier_t ier;
    ier.bits.eosacc = 1;
    *IER = ier;
  }
  async command void HplSam3uTwi1.setIntEndRx(){
    volatile twi_ier_t* IER = (volatile twi_ier_t *) (TWI1_BASE_ADDR + 0x24);
    twi_ier_t ier;
    ier.bits.endrx = 1;
    *IER = ier;
  }
  async command void HplSam3uTwi1.setIntEndTx(){
    volatile twi_ier_t* IER = (volatile twi_ier_t *) (TWI1_BASE_ADDR + 0x24);
    twi_ier_t ier;
    ier.bits.endtx = 1;
    *IER = ier;
  }
  async command void HplSam3uTwi1.setIntRxBufFull(){
    volatile twi_ier_t* IER = (volatile twi_ier_t *) (TWI1_BASE_ADDR + 0x24);
    twi_ier_t ier;
    ier.bits.rxbuff = 1;
    *IER = ier;
  }
  async command void HplSam3uTwi1.setIntTxBufEmpty(){
    volatile twi_ier_t* IER = (volatile twi_ier_t *) (TWI1_BASE_ADDR + 0x24);
    twi_ier_t ier;
    ier.bits.txbufe = 1;
    *IER = ier;
  }

  async command void HplSam3uTwi0.disIntTxComp(){
    volatile twi_idr_t* IDR = (volatile twi_idr_t *) (TWI0_BASE_ADDR + 0x28);
    twi_idr_t idr;
    idr.bits.txcomp = 1;
    *IDR = idr;
  }
  async command void HplSam3uTwi0.disIntRxReady(){
    volatile twi_idr_t* IDR = (volatile twi_idr_t *) (TWI0_BASE_ADDR + 0x28);
    twi_idr_t idr;
    idr.bits.rxrdy = 1;
    *IDR = idr;
  }
  async command void HplSam3uTwi0.disIntTxReady(){
    volatile twi_idr_t* IDR = (volatile twi_idr_t *) (TWI0_BASE_ADDR + 0x28);
    twi_idr_t idr;
    idr.bits.txrdy = 1;
    *IDR = idr;
  }
  async command void HplSam3uTwi0.disIntSlaveAccess(){
    volatile twi_idr_t* IDR = (volatile twi_idr_t *) (TWI0_BASE_ADDR + 0x28);
    twi_idr_t idr;
    idr.bits.svacc = 1;
    *IDR = idr;
  }
  async command void HplSam3uTwi0.disIntGenCallAccess(){
    volatile twi_idr_t* IDR = (volatile twi_idr_t *) (TWI0_BASE_ADDR + 0x28);
    twi_idr_t idr;
    idr.bits.gacc = 1;
    *IDR = idr;
  }
  async command void HplSam3uTwi0.disIntORErr(){
    volatile twi_idr_t* IDR = (volatile twi_idr_t *) (TWI0_BASE_ADDR + 0x28);
    twi_idr_t idr;
    idr.bits.ovre = 1;
    *IDR = idr;
  }
  async command void HplSam3uTwi0.disIntNack(){
    volatile twi_idr_t* IDR = (volatile twi_idr_t *) (TWI0_BASE_ADDR + 0x28);
    twi_idr_t idr;
    idr.bits.nack = 1;
    *IDR = idr;
  }
  async command void HplSam3uTwi0.disIntArbLost(){
    volatile twi_idr_t* IDR = (volatile twi_idr_t *) (TWI0_BASE_ADDR + 0x28);
    twi_idr_t idr;
    idr.bits.arblst = 1;
    *IDR = idr;
  }
  async command void HplSam3uTwi0.disIntClockWaitState(){
    volatile twi_idr_t* IDR = (volatile twi_idr_t *) (TWI0_BASE_ADDR + 0x28);
    twi_idr_t idr;
    idr.bits.sclws = 1;
    *IDR = idr;
  }
  async command void HplSam3uTwi0.disIntEOSAccess(){
    volatile twi_idr_t* IDR = (volatile twi_idr_t *) (TWI0_BASE_ADDR + 0x28);
    twi_idr_t idr;
    idr.bits.eosacc = 1;
    *IDR = idr;
  }
  async command void HplSam3uTwi0.disIntEndRx(){
    volatile twi_idr_t* IDR = (volatile twi_idr_t *) (TWI0_BASE_ADDR + 0x28);
    twi_idr_t idr;
    idr.bits.endrx = 1;
    *IDR = idr;
  }
  async command void HplSam3uTwi0.disIntEndTx(){
    volatile twi_idr_t* IDR = (volatile twi_idr_t *) (TWI0_BASE_ADDR + 0x28);
    twi_idr_t idr;
    idr.bits.endtx = 1;
    *IDR = idr;
  }
  async command void HplSam3uTwi0.disIntRxBufFull(){
    volatile twi_idr_t* IDR = (volatile twi_idr_t *) (TWI0_BASE_ADDR + 0x28);
    twi_idr_t idr;
    idr.bits.rxbuff = 1;
    *IDR = idr;
  }
  async command void HplSam3uTwi0.disIntTxBufEmpty(){
    volatile twi_idr_t* IDR = (volatile twi_idr_t *) (TWI0_BASE_ADDR + 0x28);
    twi_idr_t idr;
    idr.bits.txbufe = 1;
    *IDR = idr;
  }

  async command void HplSam3uTwi1.disIntTxComp(){
    volatile twi_idr_t* IDR = (volatile twi_idr_t *) (TWI1_BASE_ADDR + 0x28);
    twi_idr_t idr;
    idr.bits.txcomp = 1;
    *IDR = idr;
  }
  async command void HplSam3uTwi1.disIntRxReady(){
    volatile twi_idr_t* IDR = (volatile twi_idr_t *) (TWI1_BASE_ADDR + 0x28);
    twi_idr_t idr;
    idr.bits.rxrdy = 1;
    *IDR = idr;
  }
  async command void HplSam3uTwi1.disIntTxReady(){
    volatile twi_idr_t* IDR = (volatile twi_idr_t *) (TWI1_BASE_ADDR + 0x28);
    twi_idr_t idr;
    idr.bits.txrdy = 1;
    *IDR = idr;
  }
  async command void HplSam3uTwi1.disIntSlaveAccess(){
    volatile twi_idr_t* IDR = (volatile twi_idr_t *) (TWI1_BASE_ADDR + 0x28);
    twi_idr_t idr;
    idr.bits.svacc = 1;
    *IDR = idr;
  }
  async command void HplSam3uTwi1.disIntGenCallAccess(){
    volatile twi_idr_t* IDR = (volatile twi_idr_t *) (TWI1_BASE_ADDR + 0x28);
    twi_idr_t idr;
    idr.bits.gacc = 1;
    *IDR = idr;
  }
  async command void HplSam3uTwi1.disIntORErr(){
    volatile twi_idr_t* IDR = (volatile twi_idr_t *) (TWI1_BASE_ADDR + 0x28);
    twi_idr_t idr;
    idr.bits.ovre = 1;
    *IDR = idr;
  }
  async command void HplSam3uTwi1.disIntNack(){
    volatile twi_idr_t* IDR = (volatile twi_idr_t *) (TWI1_BASE_ADDR + 0x28);
    twi_idr_t idr;
    idr.bits.nack = 1;
    *IDR = idr;
  }
  async command void HplSam3uTwi1.disIntArbLost(){
    volatile twi_idr_t* IDR = (volatile twi_idr_t *) (TWI1_BASE_ADDR + 0x28);
    twi_idr_t idr;
    idr.bits.arblst = 1;
    *IDR = idr;
  }
  async command void HplSam3uTwi1.disIntClockWaitState(){
    volatile twi_idr_t* IDR = (volatile twi_idr_t *) (TWI1_BASE_ADDR + 0x28);
    twi_idr_t idr;
    idr.bits.sclws = 1;
    *IDR = idr;
  }
  async command void HplSam3uTwi1.disIntEOSAccess(){
    volatile twi_idr_t* IDR = (volatile twi_idr_t *) (TWI1_BASE_ADDR + 0x28);
    twi_idr_t idr;
    idr.bits.eosacc = 1;
    *IDR = idr;
  }
  async command void HplSam3uTwi1.disIntEndRx(){
    volatile twi_idr_t* IDR = (volatile twi_idr_t *) (TWI1_BASE_ADDR + 0x28);
    twi_idr_t idr;
    idr.bits.endrx = 1;
    *IDR = idr;
  }
  async command void HplSam3uTwi1.disIntEndTx(){
    volatile twi_idr_t* IDR = (volatile twi_idr_t *) (TWI1_BASE_ADDR + 0x28);
    twi_idr_t idr;
    idr.bits.endtx = 1;
    *IDR = idr;
  }
  async command void HplSam3uTwi1.disIntRxBufFull(){
    volatile twi_idr_t* IDR = (volatile twi_idr_t *) (TWI1_BASE_ADDR + 0x28);
    twi_idr_t idr;
    idr.bits.rxbuff = 1;
    *IDR = idr;
  }
  async command void HplSam3uTwi1.disIntTxBufEmpty(){
    volatile twi_idr_t* IDR = (volatile twi_idr_t *) (TWI1_BASE_ADDR + 0x28);
    twi_idr_t idr;
    idr.bits.txbufe = 1;
    *IDR = idr;
  }

  async command uint8_t HplSam3uTwi0.maskIntTxComp(){
    volatile twi_imr_t* IMR = (volatile twi_imr_t *) (TWI0_BASE_ADDR + 0x2C);
    return IMR->bits.txcomp;
  }
  async command uint8_t HplSam3uTwi0.maskIntRxReady(){
    volatile twi_imr_t* IMR = (volatile twi_imr_t *) (TWI0_BASE_ADDR + 0x2C);
    return IMR->bits.rxrdy;
  }
  async command uint8_t HplSam3uTwi0.maskIntTxReady(){
    volatile twi_imr_t* IMR = (volatile twi_imr_t *) (TWI0_BASE_ADDR + 0x2C);
    return IMR->bits.txrdy;
  }
  async command uint8_t HplSam3uTwi0.maskIntSlaveAccess(){
    volatile twi_imr_t* IMR = (volatile twi_imr_t *) (TWI0_BASE_ADDR + 0x2C);
    return IMR->bits.svacc;
  }
  async command uint8_t HplSam3uTwi0.maskIntGenCallAccess(){
    volatile twi_imr_t* IMR = (volatile twi_imr_t *) (TWI0_BASE_ADDR + 0x2C);
    return IMR->bits.gacc;
  }
  async command uint8_t HplSam3uTwi0.maskIntORErr(){
    volatile twi_imr_t* IMR = (volatile twi_imr_t *) (TWI0_BASE_ADDR + 0x2C);
    return IMR->bits.ovre;
  }
  async command uint8_t HplSam3uTwi0.maskIntNack(){
    volatile twi_imr_t* IMR = (volatile twi_imr_t *) (TWI0_BASE_ADDR + 0x2C);
    return IMR->bits.nack;
  }
  async command uint8_t HplSam3uTwi0.maskIntArbLost(){
    volatile twi_imr_t* IMR = (volatile twi_imr_t *) (TWI0_BASE_ADDR + 0x2C);
    return IMR->bits.arblst;
  }
  async command uint8_t HplSam3uTwi0.maskIntClockWaitState(){
    volatile twi_imr_t* IMR = (volatile twi_imr_t *) (TWI0_BASE_ADDR + 0x2C);
    return IMR->bits.sclws;
  }
  async command uint8_t HplSam3uTwi0.maskIntEOSAccess(){
    volatile twi_imr_t* IMR = (volatile twi_imr_t *) (TWI0_BASE_ADDR + 0x2C);
    return IMR->bits.eosacc;
  }
  async command uint8_t HplSam3uTwi0.maskIntEndRx(){
    volatile twi_imr_t* IMR = (volatile twi_imr_t *) (TWI0_BASE_ADDR + 0x2C);
    return IMR->bits.endrx;
  }
  async command uint8_t HplSam3uTwi0.maskIntEndTx(){
    volatile twi_imr_t* IMR = (volatile twi_imr_t *) (TWI0_BASE_ADDR + 0x2C);
    return IMR->bits.endtx;
  }
  async command uint8_t HplSam3uTwi0.maskIntRxBufFull(){
    volatile twi_imr_t* IMR = (volatile twi_imr_t *) (TWI0_BASE_ADDR + 0x2C);
    return IMR->bits.rxbuff;
  }
  async command uint8_t HplSam3uTwi0.maskIntTxBufEmpty(){
    volatile twi_imr_t* IMR = (volatile twi_imr_t *) (TWI0_BASE_ADDR + 0x2C);
    return IMR->bits.txbufe;
  }
  async command uint8_t HplSam3uTwi1.maskIntTxComp(){
    volatile twi_imr_t* IMR = (volatile twi_imr_t *) (TWI1_BASE_ADDR + 0x2C);
    return IMR->bits.txcomp;
  }
  async command uint8_t HplSam3uTwi1.maskIntRxReady(){
    volatile twi_imr_t* IMR = (volatile twi_imr_t *) (TWI1_BASE_ADDR + 0x2C);
    return IMR->bits.rxrdy;
  }
  async command uint8_t HplSam3uTwi1.maskIntTxReady(){
    volatile twi_imr_t* IMR = (volatile twi_imr_t *) (TWI1_BASE_ADDR + 0x2C);
    return IMR->bits.txrdy;
  }
  async command uint8_t HplSam3uTwi1.maskIntSlaveAccess(){
    volatile twi_imr_t* IMR = (volatile twi_imr_t *) (TWI1_BASE_ADDR + 0x2C);
    return IMR->bits.svacc;
  }
  async command uint8_t HplSam3uTwi1.maskIntGenCallAccess(){
    volatile twi_imr_t* IMR = (volatile twi_imr_t *) (TWI1_BASE_ADDR + 0x2C);
    return IMR->bits.gacc;
  }
  async command uint8_t HplSam3uTwi1.maskIntORErr(){
    volatile twi_imr_t* IMR = (volatile twi_imr_t *) (TWI1_BASE_ADDR + 0x2C);
    return IMR->bits.ovre;
  }
  async command uint8_t HplSam3uTwi1.maskIntNack(){
    volatile twi_imr_t* IMR = (volatile twi_imr_t *) (TWI1_BASE_ADDR + 0x2C);
    return IMR->bits.nack;
  }
  async command uint8_t HplSam3uTwi1.maskIntArbLost(){
    volatile twi_imr_t* IMR = (volatile twi_imr_t *) (TWI1_BASE_ADDR + 0x2C);
    return IMR->bits.arblst;
  }
  async command uint8_t HplSam3uTwi1.maskIntClockWaitState(){
    volatile twi_imr_t* IMR = (volatile twi_imr_t *) (TWI1_BASE_ADDR + 0x2C);
    return IMR->bits.sclws;
  }
  async command uint8_t HplSam3uTwi1.maskIntEOSAccess(){
    volatile twi_imr_t* IMR = (volatile twi_imr_t *) (TWI1_BASE_ADDR + 0x2C);
    return IMR->bits.eosacc;
  }
  async command uint8_t HplSam3uTwi1.maskIntEndRx(){
    volatile twi_imr_t* IMR = (volatile twi_imr_t *) (TWI1_BASE_ADDR + 0x2C);
    return IMR->bits.endrx;
  }
  async command uint8_t HplSam3uTwi1.maskIntEndTx(){
    volatile twi_imr_t* IMR = (volatile twi_imr_t *) (TWI1_BASE_ADDR + 0x2C);
    return IMR->bits.endtx;
  }
  async command uint8_t HplSam3uTwi1.maskIntRxBufFull(){
    volatile twi_imr_t* IMR = (volatile twi_imr_t *) (TWI1_BASE_ADDR + 0x2C);
    return IMR->bits.rxbuff;
  }
  async command uint8_t HplSam3uTwi1.maskIntTxBufEmpty(){
    volatile twi_imr_t* IMR = (volatile twi_imr_t *) (TWI1_BASE_ADDR + 0x2C);
    return IMR->bits.txbufe;
  }

  async command uint8_t HplSam3uTwi0.readRxReg(){
    volatile twi_rhr_t* RHR = (volatile twi_rhr_t *) (TWI0_BASE_ADDR + 0x30);
    return RHR->bits.rxdata;
  }
  async command uint8_t HplSam3uTwi1.readRxReg(){
    volatile twi_rhr_t* RHR = (volatile twi_rhr_t *) (TWI1_BASE_ADDR + 0x30);
    return RHR->bits.rxdata;
  }

  async command void HplSam3uTwi0.setTxReg(uint8_t buffer){
    volatile twi_thr_t* THR = (volatile twi_thr_t *) (TWI0_BASE_ADDR + 0x34);
    twi_thr_t thr = *THR;
    thr.bits.txdata = buffer;
    *THR = thr;
  }

  async command void HplSam3uTwi1.setTxReg(uint8_t buffer){
    volatile twi_thr_t* THR = (volatile twi_thr_t *) (TWI1_BASE_ADDR + 0x34);
    twi_thr_t thr = *THR;
    thr.bits.txdata = buffer;
    *THR = thr;
  }

  async event void Twi0ClockConfig.mainClockChanged(){}
  async event void Twi1ClockConfig.mainClockChanged(){}

 default async event void Interrupt0.fired(){}
 default async event void Interrupt1.fired(){}
}

