/*
 * Copyright (c) 2005 Arch Rock Corporation 
 * All rights reserved. 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *	Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *  
 *   Neither the name of the Arch Rock Corporation nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE ARCHED
 * ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
/**
 * 
 *
 * @author Kaisen Lin
 * @author Phil Buonadonna
 */

#include "SSP.h"

interface HalPXA27xSSPCntl 
{

  /**
   *configure the port to be Master of SCLK
   *
   *@param enable:  port is master of SCLK if TRUE, slave if FALSE
   *
   *@return FAIL if error, SUCCESS otherwise
   */
  command error_t setMasterSCLK(bool enable);
  
  /**
   *configure the port to be Master of SFRM
   *
   *@param enable:  port is master of SFRM if TRUE, slave if FALSE
   *
   *@return FAIL if error, SUCCESS otherwise
   */
  command error_t setMasterSFRM(bool enable);
  
  /**
   *configure the port to be in ReceiveWithoutTransmit mode
   *
   *@param enable:  port only receives if TRUE, slave if FALSE
   *
   *@return FAIL if error, SUCCESS otherwise
   */
  command error_t setReceiveWithoutTransmit(bool enable);
  
  /**
   *configure the port to be in SPI, SSP, Microwire, or PSP modes
   *
   *@param format:  format to use...see SSP.h for encodings
   *
   *@return FAIL if error, SUCCESS otherwise
   */
  command error_t setSSPFormat(SSPFrameFormat_t format);
  
  /**
   *configure how many bits wide the port should consider 1 sample
   *
   *@param width:  bits to use
   *
   *@return FAIL if error, SUCCESS otherwise
   */
  command error_t setDataWidth(SSPDataWidth_t width);
  
  /**
   *configure the port to invert the SFRM signal
   *
   *@param enable:  invert the signal if TRUE, don't invert if FALSE
   *
   *@return FAIL if error, SUCCESS otherwise
   */
  command error_t enableInvertedSFRM(bool enable);
  
  /**
   *configure the depth of the RX FIFO at which point an interrupt is generated
   *
   *@param level:  fifo level...see SSP.h for encodings
   *
   *@return FAIL if error, SUCCESS otherwise
   */
  command error_t setRxFifoLevel(SSPFifoLevel_t level);
  
  /**
   *configure the depth of the TX FIFO at which point an interrupt is generated
   *
   *@param level:  fifo level...see SSP.h for encodings
   *
   *@return FAIL if error, SUCCESS otherwise
   */
  command error_t setTxFifoLevel(SSPFifoLevel_t level);
    
  /**
   *configure the width of microwire commands
   *
   *@param size:  8 bit or 16 bit commands...see SSP.h for encodings
   *
   *@return FAIL if error, SUCCESS otherwise
   */
  command error_t setMicrowireTxSize(SSPMicrowireTxSize_t size);
  
  
  /************************************
   *clk specific configuration routines
   ************************************/
  
  /**
   *configure the clock divider for the port.
   *
   *@param clkdivider:  divider for the port...clk will be 13M/(clkdivider)
   *
   *@return FAIL if error, SUCCESS otherwise
   */
  command error_t setClkRate(uint16_t clkdivider);
  
  /**
   *configure the Clk Mode of the port. 
   *
   *@param mode:  SSP_NORMALMODE for normal operation, SSP_NETWORKMODE for 
   *              network mode
   *
   *@return FAIL if error, SUCCESS otherwise
   */
  command error_t setClkMode(SSPClkMode_t mode);

}
