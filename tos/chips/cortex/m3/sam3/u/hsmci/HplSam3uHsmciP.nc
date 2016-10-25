/*
 * Copyright (c) 2010 Johns Hopkins University.
 * Copyright (c) 2010 CSIRO Australia
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
 * High Speed Multimedia Card Interface HPL Implementations.
 *
 * @author JeongGil Ko
 * @author Kevin Klues
 */

#include <sam3uhsmcihardware.h>

module HplSam3uHsmciP {
  provides {
    interface AsyncStdControl;
    interface HplSam3uHsmci;
  } 
  uses {
    interface Leds;
    interface Init as PlatformHsmciConfig;
    interface BusyWait<TMicro, uint16_t>;
    interface HplSam3PeripheralClockCntl as HSMCIClockControl;
    interface HplNVICInterruptCntl as HSMCIInterrupt;
    interface HplSam3GeneralIOPin as HSMCIPinMCCDA;
    interface HplSam3GeneralIOPin as HSMCIPinMCCK;
    interface HplSam3GeneralIOPin as HSMCIPinMCDA0;
    interface HplSam3GeneralIOPin as HSMCIPinMCDA1;
    interface HplSam3GeneralIOPin as HSMCIPinMCDA2;
    interface HplSam3GeneralIOPin as HSMCIPinMCDA3;
    interface HplSam3GeneralIOPin as HSMCIPinMCDA4;
    interface HplSam3GeneralIOPin as HSMCIPinMCDA5;
    interface HplSam3GeneralIOPin as HSMCIPinMCDA6;
    interface HplSam3GeneralIOPin as HSMCIPinMCDA7;
    interface McuSleep;
  }
}
implementation {

  
  #define BLOCK_LENGTH (HSMCI->blkr.bits.blklen)
  #define WORDS_PER_BLOCK (BLOCK_LENGTH/4)

  enum {
    STATE_OFF,
    STATE_INACTIVE,
    STATE_IDLE,
    STATE_READY, 
    STATE_IDENTIFICATION,
    STATE_STANDBY,
    STATE_TRANSFER,
    STATE_SENDING,
    STATE_RECEIVING,
    STATE_PROGRAMMING,
    STATE_DISCONNECT,
  };

  // Protected by state variables 
  norace uint8_t state = STATE_OFF;
  norace uint8_t cmd_pending = FALSE;
  norace uint8_t current_cmd = 0;
  norace uint8_t acmd = 0;
  norace uint32_t acmd_arg = 0;
  norace uint32_t rca_addr = 0;
  norace uint8_t card_type = 0;

  norace uint32_t rsp_buf[4]; 
  norace uint32_t *rsp_buf_ptr;

  norace uint32_t words_transferred = 0;
  norace uint32_t **trans_buf;

  void configurePins() {
    // Disable all interrrupts by default
    HSMCI->idr.flat = -1; 
    
    // Configure the SD card interrupt
    call HSMCIInterrupt.configure(IRQ_PRIO_HSMCI);

    // Set up the SD card pins
    call HSMCIPinMCCDA.disablePioControl();
    call HSMCIPinMCCDA.selectPeripheralA();

    call HSMCIPinMCCK.disablePioControl();
    call HSMCIPinMCCK.selectPeripheralA();

    call HSMCIPinMCDA0.disablePioControl();
    call HSMCIPinMCDA0.selectPeripheralA();

    call HSMCIPinMCDA1.disablePioControl();
    call HSMCIPinMCDA1.selectPeripheralA();

    call HSMCIPinMCDA2.disablePioControl();
    call HSMCIPinMCDA2.selectPeripheralA();

    call HSMCIPinMCDA3.disablePioControl();
    call HSMCIPinMCDA3.selectPeripheralA();

    call HSMCIPinMCDA4.disablePioControl();
    call HSMCIPinMCDA4.selectPeripheralB();

    call HSMCIPinMCDA5.disablePioControl();
    call HSMCIPinMCDA5.selectPeripheralB();

    call HSMCIPinMCDA6.disablePioControl();
    call HSMCIPinMCDA6.selectPeripheralB();

    call HSMCIPinMCDA7.disablePioControl();
    call HSMCIPinMCDA7.selectPeripheralB();
  }

  void unlockConfigRegs() {
    // set write protection registers
    HSMCI->wpmr.bits.wp_key = 0x4D4349; // Magic key for unlocking the regs
    HSMCI->wpmr.bits.wp_en = 0;
  }

  void initConfigRegs() {
    // Enable mci
    HSMCI->cr.bits.mcien = 1;
    // Enable power save mode
    HSMCI->cr.bits.pwsdis = 0;
    // Set the multiplier for the timeout between block transfers
    HSMCI->dtor.bits.dtomul = 0x7;
    // Set timeout between block transfers
    HSMCI->dtor.bits.dtocyc = 0xF;
    // Disable all interrupts
    HSMCI->idr.flat = -1;
    // Set the clock divide
    HSMCI->mr.bits.clkdiv = 58;
    // Set padding value to 0x00, not 0xFF
    HSMCI->mr.bits.padv = 0;
    // Disable allowing byte transfers
    HSMCI->mr.bits.fbyte = 0;
    // Disable dma
    HSMCI->dma.bits.dmaen = 0;
    // Start writing data immediately when appears in FIFO
    HSMCI->cfg.bits.fifomode = 1;
    // Require a new read/write to reset an under/overflow
    HSMCI->cfg.bits.ferrctrl = 0;
    // Initialize any platform specific settings
    call PlatformHsmciConfig.init();
  }

  void swReset() {
    // set sw reset register
    HSMCI->cr.bits.swrst = 1;
  }

  void issueRealACMD(uint8_t cmd, uint32_t arg) {
    acmd = cmd;
    acmd_arg = arg;
    HSMCI->argr.bits.arg = rca_addr;
    HSMCI->cmdr.flat = AT91C_APP_CMD;
  }

  void* sendCommandDone(error_t e) {
    return signal HplSam3uHsmci.sendCommandDone(current_cmd, rsp_buf_ptr, e);
  }

  async command error_t AsyncStdControl.start() {
    // start clock, start interrupt, start pin
    call HSMCIClockControl.enable();
    return SUCCESS;
  }

  async command error_t AsyncStdControl.stop() {
    // start clock, start interrupt, start pin
    call HSMCIClockControl.disable();
    return SUCCESS;
  }

  command error_t HplSam3uHsmci.init(uint32_t **transb) {
    // Initialize the first tx and rx buffers
    trans_buf = transb;

    // Configure all of the data and interrupt pins
    configurePins();

    // Initialize state variables
    cmd_pending = FALSE;
    current_cmd = 0;
    acmd = 0;
    acmd_arg = 0;
    rca_addr = 0;
    state = STATE_OFF;
    card_type = 0;
    words_transferred = 0;
    rsp_buf_ptr = rsp_buf;

    // Reset the device
    swReset();

    // Unlock and initialize the configuration registers
    unlockConfigRegs();
    initConfigRegs();

    // Run the set of commands to switch the SD card 
    // from Card ID mode to Transfer Mode
    return call HplSam3uHsmci.sendCommand(CMD_PON, 0);
  }

  async command error_t HplSam3uHsmci.sendCommand(uint8_t command_number, uint32_t arg){
    if(cmd_pending == TRUE)
      return EBUSY;

    if(state == STATE_INACTIVE)
      return FAIL;

    // Save the current command so we can identify it in the interrupt handler
    current_cmd = command_number;

    // Set the command argument
    HSMCI->argr.bits.arg = arg;

    // Set the default values for some registers
    //HSMCI->cfg.bits.hsmode = 0;
    HSMCI->mr.bits.wrproof = 1;
    HSMCI->mr.bits.rdproof = 1;

    // Clear the response buffer for the next command
    memset(rsp_buf, 0, sizeof(rsp_buf));

    /* Card Power On */
    if(state == STATE_OFF) {
      switch(command_number) {
        case CMD_PON:
          HSMCI->cmdr.flat = AT91C_POWER_ON_INIT;
          break;
        default:
          // Notice the return here rather than the break....
          // We don't want to wait for an interrupt in this case, so just return
          return EINVAL;
      }
    }
    /* Valid Commands from any state except STATE_OFF */
    else if(command_number == CMD0) {
      HSMCI->cmdr.flat = AT91C_GO_IDLE_STATE_CMD;
    }
    else if(command_number == CMD15) {
      HSMCI->cmdr.flat = AT91C_GO_INACTIVE_STATE_CMD;
    }
    /* Card Identification Mode */
    else if(state == STATE_IDLE) {
      switch(command_number) {
        case CMD8:
          HSMCI->cmdr.flat = AT91C_SEND_IF_COND;
          break;
        case ACMD41:
          issueRealACMD(ACMD41_REAL, arg);
          break;
        case ACMD41_REAL:
          HSMCI->cmdr.flat = AT91C_SD_APP_OP_COND_CMD;
          break;
        default:
          // Notice the return here rather than the break....
          // We don't want to wait for an interrupt in this case, so just return
          return EINVAL;
      }
    }
    else if(state == STATE_READY) {
      switch(command_number) {
        // case CMD11:
          // No CMD11 needed on sam3u
        case CMD2:
          HSMCI->cmdr.flat = AT91C_ALL_SEND_CID_CMD;
          break;
        default:
          // Notice the return here rather than the break....

      }
    }
    else if(state == STATE_IDENTIFICATION) {
      switch(command_number) {
        case CMD3:
          HSMCI->cmdr.flat = AT91C_SET_RELATIVE_ADDR_CMD;
          break;
        default:
          // Notice the return here rather than the break....
          // We don't want to wait for an interrupt in this case, so just return
          return EINVAL;
      }
    }
    else if(command_number == CMD13) {
      HSMCI->cmdr.flat = AT91C_SEND_STATUS_CMD;
    }
    /* Transfer Mode */
    else if(state == STATE_STANDBY) {
      switch(command_number) {
        case CMD4:
          HSMCI->cmdr.flat =  AT91C_SET_DSR_CMD;
          break;
        case CMD9:
          HSMCI->cmdr.flat = AT91C_SEND_CSD_CMD;
          break;
        case CMD10:
          HSMCI->cmdr.flat = AT91C_SEND_CID_CMD;
          break;
        case CMD3:
          HSMCI->cmdr.flat = AT91C_SET_RELATIVE_ADDR_CMD;
          break;
        case CMD7:
          HSMCI->cmdr.flat = AT91C_SEL_DESEL_CARD_CMD;
          break;
        default:
          // Notice the return here rather than the break....
          // We don't want to wait for an interrupt in this case, so just return
          return EINVAL;
      }
    }
    else if(state == STATE_TRANSFER) {
      switch(command_number) {
        case CMD7:
          HSMCI->cmdr.flat = AT91C_SEL_DESEL_CARD_CMD;
          break;
      /* Configuration commands */
        case CMD16:
          HSMCI->blkr.bits.blklen = arg;
          HSMCI->cmdr.flat = AT91C_SET_BLOCKLEN_CMD;
          break;
        case CMD32:
          HSMCI->cmdr.flat = AT91C_TAG_SECTOR_START_CMD;
          break;
        case CMD33:
          HSMCI->cmdr.flat = AT91C_TAG_SECTOR_END_CMD;
          break;
        case ACMD6:
          issueRealACMD(ACMD6_REAL, arg);
          break;
        case ACMD42:
          issueRealACMD(ACMD42_REAL, arg);
          break;
        case ACMD23:
          issueRealACMD(ACMD23_REAL, arg);
          break;
        case ACMD6_REAL:
          HSMCI->sdcr.bits.sdcbus = arg;
          HSMCI->cmdr.flat = AT91C_SD_SET_BUS_WIDTH_CMD;
          break;
        case ACMD42_REAL:
          HSMCI->cmdr.flat = AT91C_SD_SET_CLR_CARD_DETECT_CMD;
          break;
        case ACMD23_REAL:
          HSMCI->cmdr.flat = AT91C_SD_SET_WR_BLK_ERASE_COUNT_CMD;
          break;
      /* Read commands */
        case CMD6:
          HSMCI->cmdr.flat = AT91C_MMC_SWITCH_CMD;
          break;
        case CMD17:
          if(card_type == 3)
            HSMCI->blkr.bits.blklen = 512;
          HSMCI->blkr.bits.bcnt = 1;
          words_transferred = 0;
          HSMCI->cmdr.flat = AT91C_READ_SINGLE_BLOCK_CMD;
          break;
        case CMD18:
          if(card_type == 3)
            HSMCI->blkr.bits.blklen = 512;
          HSMCI->blkr.bits.bcnt = 0;
          words_transferred = 0;
          HSMCI->cmdr.flat = AT91C_READ_MULTIPLE_BLOCK_CMD;
          break;
        case CMD56R:
          HSMCI->cmdr.flat = AT91C_GEN_CMD;
          break;
        case ACMD13:
          issueRealACMD(ACMD13_REAL, arg);
          break;
        case ACMD22:
          issueRealACMD(ACMD22_REAL, arg);
          break;
        case ACMD51:
          issueRealACMD(ACMD51_REAL, arg);
          break;
        case ACMD13_REAL:
          HSMCI->cmdr.flat = AT91C_SD_STATUS_CMD;
          break;
        case ACMD22_REAL:
          HSMCI->cmdr.flat = AT91C_SD_SEND_NUM_WR_BLOCKS_CMD;
          break;
        case ACMD51_REAL:
          HSMCI->cmdr.flat = AT91C_SD_SEND_SCR_CMD;
          break;
      /* Write commands */
        case CMD24:
          if(card_type == 3)
            HSMCI->blkr.bits.blklen = 512;
          HSMCI->blkr.bits.bcnt = 1;
          words_transferred = 0;
          HSMCI->cmdr.flat = AT91C_WRITE_BLOCK_CMD;
          break;
        case CMD25:
          if(card_type == 3)
            HSMCI->blkr.bits.blklen = 512;
          HSMCI->blkr.bits.bcnt = 0;
          words_transferred = 0;
          HSMCI->cmdr.flat = AT91C_WRITE_MULTIPLE_BLOCK_CMD;
          break;
        case CMD27:
          HSMCI->cmdr.flat = AT91C_PROGRAM_CSD_CMD;
          break;
        case CMD42:
          HSMCI->cmdr.flat = AT91C_LOCK_UNLOCK;
          break;
        case CMD56W:
          HSMCI->cmdr.flat = AT91C_GEN_CMD;
          break;
      /* Erase commands */
        case CMD38:
          HSMCI->cmdr.flat = AT91C_ERASE_CMD;
          break;
        default:
          // Notice the return here rather than the break....
          // We don't want to wait for an interrupt in this case, so just return
          return EINVAL;
      }
    }
    else if(state == STATE_SENDING) {
      switch(command_number) {
        case CMD7:
          HSMCI->cmdr.flat = AT91C_SEL_DESEL_CARD_CMD;
          break;
        case CMD12:
          HSMCI->cmdr.flat = AT91C_STOP_TRANSMISSION_CMD;
          break;
        default:
          // Notice the return here rather than the break....
          // We don't want to wait for an interrupt in this case, so just return
          return EINVAL;
      }
    }
    else if(state == STATE_RECEIVING) {
      switch(command_number) {
        case CMD12:
          HSMCI->cmdr.flat = AT91C_STOP_TRANSMISSION_CMD;
          break;
        default:
          // Notice the return here rather than the break....
          // We don't want to wait for an interrupt in this case, so just return
          return EINVAL;
      }
    }
    else if(state == STATE_PROGRAMMING) {
      switch(command_number) {
        case CMD7:
          HSMCI->cmdr.flat = AT91C_SEL_DESEL_CARD_CMD;
          break;
        default:
          // Notice the return here rather than the break....
          // We don't want to wait for an interrupt in this case, so just return
          return EINVAL;
      }
    }
    else if(state == STATE_DISCONNECT) {
      switch(command_number) {
        case CMD7:
          HSMCI->cmdr.flat = AT91C_SEL_DESEL_CARD_CMD;
          break;
        default:
          // Notice the return here rather than the break....
          // We don't want to wait for an interrupt in this case, so just return
          return EINVAL;
      }
    }
    else return EINVAL;

    // if the command was valid, set the cmd_pending flag to TRUE
    // so we can't try and issue another commend in the process
    cmd_pending = TRUE;

    // Unmask the cmdrdy interrupt and turn on interrupts
    HSMCI->ier.bits.cmdrdy = 1;
    call HSMCIInterrupt.enable();
    return SUCCESS;
  }

  // Handle events
  void handler() @spontaneous() {
    int i;

//    if(statusError() && (current_cmd != 40)) {
//      printf("CMD: %d\n", current_cmd);
//      printStatus();
//    }

    // Disable interrupts while processing the response
    // They will be reenabled either below (in the case of a long read/write) 
    // or when the next command comes in
    call HSMCIInterrupt.disable();
    cmd_pending = FALSE;

    // Copy the response buffer so we can pass it back up 
    // Note that the last 8 bits of the rspr as specified in the SD spec are cut off
    // i.e. the stop bit and the CRC are not included in what is read out of rspr
    //memcpy(rsp_buf_ptr, (void*)HSMCI->rspr, sizeof(rsp_buf));
    for(i=3; i>=0; i--)
      rsp_buf_ptr[i] = HSMCI->rspr[0].flat;

    /* Card Power On */
    if(state == STATE_OFF) {
      switch(current_cmd) {
        case CMD_PON:
          state = STATE_IDLE;
          call HplSam3uHsmci.sendCommand(CMD0, 0);
          return;
        default:
          // should never get here!!
          signal HplSam3uHsmci.initDone(0, EINVAL);
          return;
      }
    }
    /* Valid Commands from any state except STATE_OFF */
    else if(current_cmd == CMD0) {
      state = STATE_IDLE;
      call HplSam3uHsmci.sendCommand(CMD8, ((uint32_t)(1<<8) | (0xAA)));
      return;
    }
    else if(current_cmd == CMD15) {
      state = STATE_INACTIVE;
      return;
    }
    /* Card Identification Mode */
    else if(state == STATE_IDLE) {
      switch(current_cmd) {
        case CMD8:
          if(HSMCI->sr.bits.rtoe) { // response time out...
            // Implies either 
            // 1) Voltage Mismatch for 2.0 or greater cards
            // 2) Version 1.x SD card
            // 3) Not an SD card
            // Send ACMD41 with HCS = 0
            card_type = 1;
            call HplSam3uHsmci.sendCommand(ACMD41, AT91C_MMC_HOST_VOLTAGE_RANGE);
          }
          else { // Version 2.0 or later SD card
            hsmci_sd_r7_t* rsp = (hsmci_sd_r7_t*)rsp_buf_ptr;
            card_type = 2;
            // Check that the voltage range and check pattern are correct
            if((rsp->vrange == 1) && (rsp->cpattern == 0xAA)) {
              // Send ACMD41 with HCS = 1
              call HplSam3uHsmci.sendCommand(ACMD41, (1 << 30) | AT91C_MMC_HOST_VOLTAGE_RANGE);
            }
            else {
              signal HplSam3uHsmci.initDone(0, FAIL);
            }
          }
          return;
        case ACMD41:
          call HplSam3uHsmci.sendCommand(acmd, acmd_arg);
          return;
        case ACMD41_REAL:
          if((card_type == 1) && HSMCI->sr.bits.rtoe) { // response time out...
            // Not an SD card
            signal HplSam3uHsmci.initDone(0, FAIL);
          }
          else {
            hsmci_sd_r3_t* rsp = (hsmci_sd_r3_t*)rsp_buf_ptr;
            if(!rsp->ocr.busy) { // If the card is busy
              // Resend ACMD41 with same argument as before
              call HplSam3uHsmci.sendCommand(ACMD41, (1 << 30) | AT91C_MMC_HOST_VOLTAGE_RANGE);
            }
            else {
              if(rsp->ocr.ccs) { // The card is high or extended capacity
                card_type = 3;
              }
              // Ignore check of of s18a and s18r becuase we know we set s18r=0
              // Call CMD2
              state = STATE_READY;
              call HplSam3uHsmci.sendCommand(CMD2, 0);
            }
          }
          return;
        default:
          // should never get here!!
          signal HplSam3uHsmci.initDone(0, EINVAL);
          return;
      }
    }
    else if(state == STATE_READY) {
      switch(current_cmd) {
        case CMD2:
          state = STATE_IDENTIFICATION;
          call HplSam3uHsmci.sendCommand(CMD3, 0);
          return;
        default:
          // should never get here!!
          signal HplSam3uHsmci.initDone(0, EINVAL);
          return;
      }
    }
    else if(state == STATE_IDENTIFICATION) {
      switch(current_cmd) {
        case CMD3:
          state = STATE_STANDBY;
          rca_addr = (((hsmci_sd_r6_t*)rsp_buf_ptr)->rca << 16);
          signal HplSam3uHsmci.initDone((hsmci_sd_r6_t*)rsp_buf_ptr, SUCCESS);
          return;
        default:
          // should never get here!!
          signal HplSam3uHsmci.initDone(0, EINVAL);
          return;
      }
    }
    /* Transfer Mode */
    else if(state == STATE_STANDBY) {
      switch(current_cmd) {
        case CMD13:
        case CMD4:
        case CMD9:
        case CMD10:
        case CMD3:
          // State doesn't change
          break;
        case CMD7:
            state = STATE_TRANSFER;
          break;
        default:
         // Notice the return here rather than the break....
         rsp_buf_ptr = sendCommandDone(EINVAL);
         return;
      }
    }
    else if(state == STATE_TRANSFER) {
      switch(current_cmd) {
        case CMD7:
          state = STATE_STANDBY;
          break;
      /* Configuration commands */
        case ACMD6:
        case ACMD42:
        case ACMD23:
          call HplSam3uHsmci.sendCommand(acmd, acmd_arg);
          return;
        case ACMD6_REAL:
        case ACMD42_REAL:
        case ACMD23_REAL:
          current_cmd -= 1; //Notice order in the .h file
        case CMD13:
        case CMD16:
        case CMD32:
        case CMD33:
          // State doesn't change
          break;
      /* Read commands */
        case ACMD13:
        case ACMD22:
        case ACMD51:
          call HplSam3uHsmci.sendCommand(acmd, acmd_arg);
          return;
        case ACMD13_REAL:
        case ACMD22_REAL:
        case ACMD51_REAL:
          current_cmd -= 1; //Notice order in the .h file
        case CMD6:
        case CMD17:
        case CMD18:
        case CMD56R:
          // Seems backwards, but is from perspective of card
          state = STATE_SENDING; 
          HSMCI->ier.bits.rxrdy = 1;
          call HSMCIInterrupt.enable();
          break;
      /* Write commands */
        case CMD24:
        case CMD25:
        case CMD27:
        case CMD42:
        case CMD56W:
          // Seems backwards, but is from perspective of card
          state = STATE_RECEIVING;
          HSMCI->ier.bits.txrdy = 1;
          HSMCI->tdr.bits.data = (*trans_buf)[words_transferred];
          call HSMCIInterrupt.enable();
          break;
      /* Erase commands */
        case CMD38:
          state = STATE_PROGRAMMING;
          break;
        default:
          // Notice the return here rather than the break....
          rsp_buf_ptr = sendCommandDone(EINVAL);
          return;
      }
    }
    else if(state == STATE_SENDING) {
      switch(current_cmd) {
        case CMD7:
          words_transferred = 0;
          HSMCI->idr.bits.rxrdy = 1;
          state = STATE_STANDBY;
          signal HplSam3uHsmci.rxDone(ECANCEL);
          break;
        case CMD12:
          // Only called in the case of canceling
          words_transferred = 0;
          HSMCI->idr.bits.rxrdy = 1;
          state = STATE_TRANSFER;
          signal HplSam3uHsmci.rxDone(ECANCEL);
          return;
        case CMD17:
          // Double check we are really ready to receive
          while(!HSMCI->sr.bits.rxrdy);
          // Get the next word
          (*trans_buf)[words_transferred] = HSMCI->rdr.bits.data;
          words_transferred++;
          // Once we've gotten a whole block, we're done
          if(words_transferred == WORDS_PER_BLOCK) {
            words_transferred = 0;
            HSMCI->idr.bits.rxrdy = 1;
            while(!HSMCI->sr.bits.xfrdone);
            state = STATE_TRANSFER;
            signal HplSam3uHsmci.rxDone(SUCCESS);
          }
          else 
            call HSMCIInterrupt.enable();
          return;
        default:
          // Notice the return here rather than the break....
          rsp_buf_ptr = sendCommandDone(EINVAL);
          return;
      }
    }
    else if(state == STATE_RECEIVING) {
      switch(current_cmd) {
        case CMD12:
          // Only called when canceling
          words_transferred = 0;
          HSMCI->idr.bits.txrdy = 1;
          state = STATE_PROGRAMMING;
          signal HplSam3uHsmci.txDone(ECANCEL);
          return;
        case CMD24:
          // Double check we are really ready to transmit
          while(!HSMCI->sr.bits.txrdy);
          words_transferred++;
          // Once we've transferred a whole block we are done
          if(words_transferred == WORDS_PER_BLOCK) {
            words_transferred = 0;
            HSMCI->idr.bits.txrdy = 1;
            state = STATE_PROGRAMMING;
            call HplSam3uHsmci.sendCommand(CMD13, 0);
            return;
          }
          HSMCI->tdr.bits.data = (*trans_buf)[words_transferred];
          call HSMCIInterrupt.enable();
          return;
        default:
          // Notice the return here rather than the break....
          rsp_buf_ptr = sendCommandDone(EINVAL);
          return;
      }
    }
    else if(state == STATE_PROGRAMMING) {
      switch(current_cmd) {
        case CMD7:
          state = STATE_DISCONNECT;
          break;
        case CMD13:
          {
            hsmci_sd_r1_t *r1 = (hsmci_sd_r1_t*)rsp_buf_ptr;
            if((r1->status & STATUS_PRG) == STATUS_PRG)
              call HplSam3uHsmci.sendCommand(CMD13, 0);
            else {
              // Go back to the transfer state
              state = STATE_TRANSFER;
              // Double check that the whole transfer has completed
              // and signal that it is done.
              // These commands only valid if transfer just made
              // For now it is always the case
              // Eventually we will need to consider CMD20,28,29,38 though
              while(!HSMCI->sr.bits.xfrdone);
              signal HplSam3uHsmci.txDone(SUCCESS);
            }
          }
          return;
        default:
          // Notice the return here rather than the break....
          rsp_buf_ptr = sendCommandDone(EINVAL);
          return;
      }
    }
    else if(state == STATE_DISCONNECT) {
      switch(current_cmd) {
        case CMD7:
          state = STATE_PROGRAMMING;
          break;
        case CMD13:
          {
            hsmci_sd_r1_t *r1 = (hsmci_sd_r1_t*)rsp_buf_ptr;
            if((r1->status & STATUS_DIS) == STATUS_DIS)
              call HplSam3uHsmci.sendCommand(CMD13, 0);
          }
          return;
        default:
          // Notice the return here rather than the break....
          rsp_buf_ptr = sendCommandDone(EINVAL);
          return;
      }
    }
    else {
      rsp_buf_ptr = sendCommandDone(EINVAL);
      return;
    }

    // Do a buffer swap with the upper layer for the response buffer
    rsp_buf_ptr = sendCommandDone(SUCCESS);
  }

  __attribute__((interrupt)) void HsmciIrqHandler() @C() @spontaneous() {
    call McuSleep.irq_preamble();
    handler();
    call McuSleep.irq_postamble();
  }
}

