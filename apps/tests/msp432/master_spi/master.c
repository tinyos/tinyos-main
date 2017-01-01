/*
 * Copyright (c) 2016, Eric B. Decker
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * *  Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * *  Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * *  Neither the name of Texas Instruments Incorporated nor the names of
 *    its contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * --/COPYRIGHT--*/

/*******************************************************************************
 * MSP432 DMA - master/slave eUSCI SPI Transfer Using DMA
 *
 * Loosly based on dma_eusci_spi_loopback.c but significantly different.
 * Converted to TinyOS.
 *
 * Two exp-msp432p401r launch pads are connected back to back.  DMA is used
 * to transfer data from the master to the slave.  Full duplex.
 *
 * B0 is used on both the master and slave and connected as shown below.  Two
 * dma channels are used on the master and two on the slave.  1 for TX and
 * 1 for RX.  Clocking is controlled by the Master.
 *
 *
 *                      MSP432P401
 *             --------------------------
 *         /|\|                          |
 *          | |                          |
 *          --|RST           P1.5 (CLK)  |-------------
 *            |              P1.6 (SIMO) |----------  |
 *            |              P1.7 (SOMI) |-------- |  |
 *            |                          |       | |  |
 *            |   2.6            2.7     |       | |  |
 *            |  master         slave    |       | |  |
 *            |   rdy            rdy     |       | |  |
 *             --------------------------        | |  |
 *                 |              ^              | |  |
 *                 |              |              | |  |
 *                 |              |              | |  |
 *                 |              |              | |  |
 *                 v              |              | |  |
 *             --------------------------        | |  |
 *            |   rdy            rdy     |       | |  |
 *            |  master         slave    |       | |  |
 *            |   2.6            2.7     |       | |  |
 *            |                          |       | |  |
 *            |              P1.7 (SOMI) |-------- |  |
 *            |              P1.6 (SIMO) |----------  |
 *            |              P1.5 (CLK)  |-------------
 *            |                          |
 *            |                          |
 *             --------------------------
 *
 *
 ******************************************************************************/


#include <stdint.h>
#include <string.h>
#include <stdbool.h>
#include <msp432usci.h>
#include <msp432dma.h>
#include <driverlib.h>

/*
 * SPI Configuration Parameters
 *
 * Master: spi mode 0, change on rising, capture on falling, inactive low,
 *         MSB first, 8 bit, Master, SMCLK/2
 */
const msp432_usci_config_t spiMasterCfg = {
    ctlw0 : (EUSCI_B_CTLW0_MSB  | EUSCI_B_CTLW0_MST | EUSCI_B_CTLW0_SYNC |
             EUSCI_B_CTLW0_SSEL__SMCLK),
    brw   : 2,                  /* 8MHz/2 -> 4 MHz */
    mctlw : 0,                  /* Always 0 in SPI mode */
    i2coa : 0
};

/*
 * Slave: spi mode 0, change on rising, capture on falling, inactive low,
 *         MSB first, 8 bit.
 */
const msp432_usci_config_t spiSlaveCfg = {
    ctlw0 : (EUSCI_B_CTLW0_MSB  | EUSCI_B_CTLW0_SYNC |
             EUSCI_B_CTLW0_SSEL__SMCLK),
    brw   : 2,                  /* not used on slave */
    mctlw : 0,                  /* Always 0 in SPI mode */
    i2coa : 0
};


const eUSCI_SPI_MasterConfig spiMasterConfig =
  { EUSCI_B_SPI_CLOCKSOURCE_SMCLK, 8388608, 8388608/2,
    EUSCI_B_SPI_MSB_FIRST,
    EUSCI_SPI_PHASE_DATA_CHANGED_ONFIRST_CAPTURED_ON_NEXT,
    EUSCI_SPI_CLOCKPOLARITY_INACTIVITY_LOW, EUSCI_B_SPI_3PIN
  };

const eUSCI_SPI_SlaveConfig spiSlaveConfig =
  { EUSCI_B_SPI_MSB_FIRST,
    EUSCI_SPI_PHASE_DATA_CHANGED_ONFIRST_CAPTURED_ON_NEXT,
    EUSCI_B_SPI_CLOCKPOLARITY_INACTIVITY_LOW,
    EUSCI_B_SPI_3PIN
  };

typedef struct {
  volatile uint32_t src_end;
  volatile uint32_t dst_end;
  volatile uint32_t control;
  volatile uint32_t pad;
} dma_cb_t;

/*
 * 8 channels, each control block is 16 bytes * 8 * 2
 * one for the primary, one for the alternate, 256 bytes.
 * The control blocks have to be aligned on a 256 byte
 * boundary.
 */
dma_cb_t ControlTable[16] __attribute__ ((aligned (0x100)));

#define MSG_LENGTH    32

uint32_t volatile isrCounter = 0;
uint8_t  dmaTxData[MSG_LENGTH];
uint8_t  dmaRxData[MSG_LENGTH];

#define APTR(x) ((EUSCI_A_Type *) x)
#define BPTR(x) ((EUSCI_B_Type *) x)

void initSPI(void * up, const msp432_usci_config_t *config, bool isB) {
  if (isB) {
    BPTR(up)->CTLW0  = config->ctlw0 | EUSCI_B_CTLW0_SWRST;
    BPTR(up)->BRW    = config->brw;
    BPTR(up)->I2COA0 = config->i2coa;
    return;
  }
  APTR(up)->CTLW0  = config->ctlw0 | EUSCI_B_CTLW0_SWRST;
  APTR(up)->BRW    = config->brw;
  APTR(up)->MCTLW = config->mctlw;
}


void dma_init(void * table) {
  BITBAND_PERI(DMA_Control->CFG, DMA_CFG_MASTEN_OFS) = 1;
  DMA_Control->CTLBASE = (uint32_t) table;
}


void dma_set_channel(uint32_t chan, uint32_t trigger, uint32_t length,
                     void * dst, void * src, uint32_t control) {
  dma_cb_t *cb;
  uint32_t src_inc, dst_inc;
  uint32_t nm1, mod;

  dst_inc = (control & UDMA_CHCTL_DSTINC_M);
  src_inc = (control & UDMA_CHCTL_SRCINC_M);
  nm1 = length - 1;
  cb = &ControlTable[chan];
  DMA_Channel->CH_SRCCFG[chan] = trigger;
  cb->control = control | nm1 << 4;
  switch (dst_inc) {
    case UDMA_CHCTL_DSTINC_8:       mod = nm1;      break;
    case UDMA_CHCTL_DSTINC_16:      mod = nm1 << 1; break;
    case UDMA_CHCTL_DSTINC_32:      mod = nm1 << 2; break;
    default:
    case UDMA_CHCTL_DSTINC_NONE:    mod = 0;        break;
  }
  cb->dst_end = (uint32_t) dst + mod;

  switch (src_inc) {
    case UDMA_CHCTL_SRCINC_8:       mod = nm1;      break;
    case UDMA_CHCTL_SRCINC_16:      mod = nm1 << 1; break;
    case UDMA_CHCTL_SRCINC_32:      mod = nm1 << 2; break;
    default:
    case UDMA_CHCTL_SRCINC_NONE:    mod = 0;        break;
  }
  cb->src_end = (uint32_t) src + mod;
}


int main(void) {
    volatile uint32_t i;

    /* Halting Watchdog */
    MAP_WDT_A_holdTimer();

#ifdef SLAVE
    for (i = 0; i < 32; i++) {
      dmaTxData[i] = 0x80 + i;
      dmaRxData[i] = 0x8f;
    }

    /*
     * configure masterRdy/slaveRdy for Slave
     *
     * on reset all ports are inputs and set to port,  2.6 is masterRdy
     * we need REN.6 set to 1 and OUT.6 set to 0 for the pulldown.
     * masterRdy is an input with a pulldown.
     *
     * P2.7 is slaveRdy, make sure it starts off.
     */
    BITBAND_PERI(P2->REN, 6) = 1;                               /* turn on resistor */
    BITBAND_PERI(P2->OUT, 6) = 0;                               /* pull down */
    BITBAND_PERI(P2->OUT, 7) = 0;                               /* make sure slaveRdy off */
    BITBAND_PERI(P2->DIR, 7) = 1;                               /* slaveRdy  is output */

    /*
     * CLK, SIMO, SOMI for SPI0 as Slave
     */
    BITBAND_PERI(EUSCI_B0->CTLW0, EUSCI_B_CTLW0_SWRST_OFS) = 1; /* hold in reset till master says proceed */
    P1->SEL0 |=  (BIT7 | BIT6 | BIT5);                          /* give 1.[5-7] to module */
    P1->SEL1 &= ~(BIT7 | BIT6 | BIT5);

    /*
     * wait for the master to request something by bringing masterRdy up
     * master needs to make sure that it does something reasonable with
     * CLK so the slave doesn't see any transitions before it is ready.
     *
     * Master won't start clocking until after we bring slaveRdy up.
     */
    while ((P2->IN & GPIO_PIN6) == 0) ;

    initSPI(EUSCI_B0, &spiSlaveCfg, 1);

    /* take out of reset */
    BITBAND_PERI(EUSCI_B0->CTLW0, EUSCI_B_CTLW0_SWRST_OFS) = 0;
    __DSB();
#else
    for (i = 0; i < 32; i++) {
      dmaTxData[i] = i + 1;
      dmaRxData[i] = 0xf8;
    }

    /*
     * configure masterRdy/slaveRdy for Master.
     *
     * on reset all ports are inputs and set to port,  2.6 is masterRdy
     * slaveRdy is 2.7 and needs a pulldown so the default is not ready.
     * we need REN.7 set to 1 and OUT.7 set to 0 for the pulldown.
     *
     * P2.6 is masterRdy, make sure it starts off.
     */
    BITBAND_PERI(P2->OUT, 6) = 0;                               /* make sure masterRdy off */
    BITBAND_PERI(P2->DIR, 6) = 1;                               /* masterRdy  is output */
    BITBAND_PERI(P2->REN, 7) = 1;                               /* turn on resistor */
    BITBAND_PERI(P2->OUT, 7) = 0;                               /* pull down */

    /*
     * CLK, SIMO, SOMI for SPI0 as Master
     */
    BITBAND_PERI(P1->OUT, 5) = 0;                               /* make sure clock is down */
    BITBAND_PERI(P1->DIR, 5) = 1;
    P1->SEL0 |=  (BIT7 | BIT6 | BIT5);                          /* give 1.[5-7] to module */
    P1->SEL1 &= ~(BIT7 | BIT6 | BIT5);
    initSPI(EUSCI_B0, &spiMasterCfg, 1);

    /* take out of reset */
    BITBAND_PERI(EUSCI_B0->CTLW0, EUSCI_B_CTLW0_SWRST_OFS) = 0;

    BITBAND_PERI(P2->OUT, 6) = 1;               /* set masterRdy */

    while ((P2->IN & GPIO_PIN7) == 0) ;         /* spin waiting for slaveRdy */
#endif

    dma_init(ControlTable);

    /* Channel 0, drives  spi->tx   <-  dmaTxData */
    dma_set_channel(0, MSP432_DMA_CH0_B0_TX0, MSG_LENGTH,
                    (void *) &(EUSCI_B0->TXBUF), dmaTxData,
                    UDMA_CHCTL_DSTINC_NONE | UDMA_CHCTL_SRCINC_8 |
                    MSP432_UDMA_SIZE_8     |
                    UDMA_CHCTL_ARBSIZE_1   |
                    UDMA_MODE_BASIC);

    /* Channel 1, drives  dmaRxData <- spi->rx */
    dma_set_channel(1, MSP432_DMA_CH1_B0_RX0, MSG_LENGTH,
                    dmaRxData, (void *) &(EUSCI_B0->RXBUF),
                    UDMA_CHCTL_DSTINC_8  | UDMA_CHCTL_SRCINC_NONE |
                    MSP432_UDMA_SIZE_8   |
                    UDMA_CHCTL_ARBSIZE_1 |
                    UDMA_MODE_BASIC);

    /* Enable DMA interrupt */
    MAP_DMA_assignInterrupt(INT_DMA_INT1, 1);
    MAP_DMA_clearInterruptFlag(DMA_CH1_EUSCIB0RX0 & 0x0F);

    /* Assigning/Enabling Interrupts */
    MAP_Interrupt_enableInterrupt(INT_DMA_INT1);
    MAP_DMA_enableInterrupt(INT_DMA_INT1);
    MAP_Interrupt_enableMaster();

    DMA_Control->PRIOSET = 1 << 1;      /* give receiver priority  */

    MAP_DMA_enableChannel(1);           /* dmaRx */
    MAP_DMA_enableChannel(0);           /* dmaTx */
    __NOP();

#ifdef SLAVE
    __DMB();
    BITBAND_PERI(P2->OUT, 7) = 1;       /* set slaveRdy */
#endif

    while (1) {
        if (isrCounter > 0) {
          __NOP();
        }
    }
}


void DMA_INT1_Handler(void) {
    isrCounter++;
    MAP_DMA_clearInterruptFlag(0);
    MAP_DMA_clearInterruptFlag(1);

    /* Disable the interrupt to allow execution */
    MAP_Interrupt_disableInterrupt(INT_DMA_INT1);
    MAP_DMA_disableInterrupt(INT_DMA_INT1);
#ifdef SLAVE
    BITBAND_PERI(P2->OUT, 7) = 0;       /* clr slaveRdy */
#else
    BITBAND_PERI(P2->OUT, 6) = 0;       /* clr masterRdy */
#endif
}
