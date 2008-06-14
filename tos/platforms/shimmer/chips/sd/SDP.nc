/* ***********************************************************
* THIS PROGRAM IS PROVIDED "AS IS". TI MAKES NO WARRANTIES OR
* REPRESENTATIONS, EITHER EXPRESS, IMPLIED OR STATUTORY, 
* INCLUDING ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS 
* FOR A PARTICULAR PURPOSE, LACK OF VIRUSES, ACCURACY OR 
* COMPLETENESS OF RESPONSES, RESULTS AND LACK OF NEGLIGENCE. 
* TI DISCLAIMS ANY WARRANTY OF TITLE, QUIET ENJOYMENT, QUIET 
* POSSESSION, AND NON-INFRINGEMENT OF ANY THIRD PARTY 
* INTELLECTUAL PROPERTY RIGHTS WITH REGARD TO THE PROGRAM OR 
* YOUR USE OF THE PROGRAM.
*
* IN NO EVENT SHALL TI BE LIABLE FOR ANY SPECIAL, INCIDENTAL, 
* CONSEQUENTIAL OR INDIRECT DAMAGES, HOWEVER CAUSED, ON ANY 
* THEORY OF LIABILITY AND WHETHER OR NOT TI HAS BEEN ADVISED 
* OF THE POSSIBILITY OF SUCH DAMAGES, ARISING IN ANY WAY OUT 
* OF THIS AGREEMENT, THE PROGRAM, OR YOUR USE OF THE PROGRAM. 
* EXCLUDED DAMAGES INCLUDE, BUT ARE NOT LIMITED TO, COST OF 
* REMOVAL OR REINSTALLATION, COMPUTER TIME, LABOR COSTS, LOSS 
* OF GOODWILL, LOSS OF PROFITS, LOSS OF SAVINGS, OR LOSS OF 
* USE OR INTERRUPTION OF BUSINESS. IN NO EVENT WILL TI'S 
* AGGREGATE LIABILITY UNDER THIS AGREEMENT OR ARISING OUT OF 
* YOUR USE OF THE PROGRAM EXCEED FIVE HUNDRED DOLLARS 
* (U.S.$500).
*
* Unless otherwise stated, the Program written and copyrighted 
* by Texas Instruments is distributed as "freeware".  You may, 
* only under TI's copyright in the Program, use and modify the 
* Program without any charge or restriction.  You may 
* distribute to third parties, provided that you transfer a 
* copy of this license to the third party and the third party 
* agrees to these terms by its first use of the Program. You 
* must reproduce the copyright notice and any other legend of 
* ownership on each copy or partial copy, of the Program.
*
* You acknowledge and agree that the Program contains 
* copyrighted material, trade secrets and other TI proprietary 
* information and is protected by copyright laws, 
* international copyright treaties, and trade secret laws, as 
* well as other intellectual property laws.  To protect TI's 
* rights in the Program, you agree not to decompile, reverse 
* engineer, disassemble or otherwise translate any object code 
* versions of the Program to a human-readable form.  You agree 
* that in no event will you alter, remove or destroy any 
* copyright notice included in the Program.  TI reserves all 
* rights not specifically granted under this license. Except 
* as specifically provided herein, nothing in this agreement 
* shall be construed as conferring by implication, estoppel, 
* or otherwise, upon you, any license or other right under any 
* TI patents, copyrights or trade secrets.
*
* You may not use the Program in non-TI devices.
* ********************************************************* */

/*
 * Copyright (c) 2006, Intel Corporation
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 * Redistributions of source code must retain the above copyright notice, 
 * this list of conditions and the following disclaimer. 
 *
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution. 
 *
 * Neither the name of the Intel Corporation nor the names of its contributors
 * may be used to endorse or promote products derived from this software 
 * without specific prior written permission. 
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
 * POSSIBILITY OF SUCH DAMAGE.
 *
 * Operations for communciating with an SD card via a standard sd card slot.
 *
 * functional pieces based upon or copied from Texas Instruments sample code
 *
 */
 /**                                   
 * @author Steve Ayer
 * @author Konrad Lorincz
 * @date March 25, 2008 - ported to TOS 2.x
 */

#include "SD.h"

module SDP 
{
    provides interface SD;

    uses interface Boot;
    uses interface HplMsp430Usart;
    uses interface HplMsp430UsartInterrupts;
}
implementation 
{                                                                      

#define SPI_TX_DONE        while(call HplMsp430Usart.isTxEmpty() == FALSE);

#define CS_LOW()    TOSH_CLR_SD_CS_N_PIN();              // Card Select
#define CS_HIGH()   SPI_TX_DONE; TOSH_SET_SD_CS_N_PIN();

    async event void HplMsp430UsartInterrupts.txDone()             {/*do nothing*/}
    async event void HplMsp430UsartInterrupts.rxDone(uint8_t data) {/*do nothing*/}

    event void Boot.booted()
    {
        call SD.init();
    }

  // This is from TOS 1.x!
  void setModeSPI()
  {
      // call USARTControl.disableUART();
      atomic ME1 &= ~(UTXE0 | URXE0);   // USART0 UART module enable
      TOSH_SEL_UTXD0_IOFUNC();
      TOSH_SEL_URXD0_IOFUNC();

      //call USARTControl.disableI2C();
      //#ifdef __msp430_have_usart0_with_i2c
      //if (call USARTControl.isI2C())
        atomic U0CTL &= ~(I2C | I2CEN | SYNC);
      //#endif


    atomic {
      TOSH_SEL_SIMO0_MODFUNC();
      TOSH_SEL_SOMI0_MODFUNC();
      TOSH_SEL_UCLK0_MODFUNC();

      IE1 &= ~(UTXIE0 | URXIE0);  // interrupt disable    

      U0CTL = SWRST;
      U0CTL |= CHAR | SYNC | MM;  // 8-bit char, SPI-mode, USART as master
      U0CTL &= ~(0x20); 

      U0TCTL = STC ;     // 3-pin
      U0TCTL |= CKPH;    // half-cycle delayed UCLK

      // call USARTControl.setClockSource(SSEL_SMCLK)
      U0TCTL &= ~(SSEL_0 | SSEL_1 | SSEL_2 | SSEL_3);
      U0TCTL |= (SSEL_SMCLK & 0x7F); 

      // call USARTControl.setClockRate(UBR_SMCLK_115200, UMCTL_SMCLK_115200);
      // UBR_SMCLK_115200=0x0009, UMCTL_SMCLK_115200=0x10,
      U0BR0 = 0x0009 & 0x0FF;
      U0BR1 = ((0x0009) >> 8) & 0x0FF;
      U0MCTL = 0x10;

      ME1 &= ~(UTXE0 | URXE0); //USART UART module disable
      ME1 |= USPIE0;   // USART SPI module enable
      U0CTL &= ~SWRST;  

      IFG1 &= ~(UTXIFG0 | URXIFG0);
      IE1 &= ~(UTXIE0 | URXIE0);  // interrupt disabled    
    }
  }

  // setup usart1 in spi mode
  void initSPI() {
    TOSH_MAKE_SD_CS_N_OUTPUT();
    TOSH_SEL_SD_CS_N_IOFUNC();

    // call USARTControl.setClockSource(SSEL_SMCLK);
    // call USARTControl.setClockRate(UBR_SMCLK_115200, UMCTL_SMCLK_115200);
    // call USARTControl.setModeSPI();
    setModeSPI();  // the above 3 commands are implemented in this call

    TOSH_SET_SD_CS_N_PIN();

    while(call HplMsp430Usart.isTxEmpty() == FALSE);
  }

  uint8_t spiSendByte (const uint8_t data){
    atomic{
      while(call HplMsp430Usart.isTxEmpty() == FALSE);   

      call HplMsp430Usart.tx(data);

      while(call HplMsp430Usart.isRxIntrPending() == FALSE);    // rx buffer has a character
    }
    
    return call HplMsp430Usart.rx();
  }
    
  void sendCmd(const uint8_t cmd, uint32_t data, const uint8_t crc){
    uint8_t frame[6];
    register int8_t i;

    frame[0] = cmd | 0x40;
    for(i = 3; i >= 0; i--)
      frame[4 - i] = (uint8_t)(data >> 8 * i);

    frame[5] = crc;
    for(i = 0; i < 6; i++)
      spiSendByte(frame[i]);
  }

  /* Response comes 1-8bytes after command
   * the first bit will be a 0
   * followed by an error code
   * data will be 0xff until response
   */
  uint8_t getResponse()
  {
    register int i=0;
    uint8_t response;

    for(i = 0; i < 65; i++){
      if(((response = spiSendByte(0xff)) == 0x00) | 
	 (response == 0x01))
	break;
    }
    return response;
  }

  uint8_t getXXResponse(const uint8_t resp){
    register uint16_t i;
    uint8_t response;
    
    for(i = 0; i < 1001; i++)
      if((response = spiSendByte(0xff)) == resp)
	break;
    
    return response;
  }

  uint8_t checkBusy(){
    register uint8_t i, j;
    uint8_t response, rvalue;
    
    for(i = 0; i < 65; i++){
      response = spiSendByte(0xff);
      response &= 0x1f;

      switch(response){
      case 0x05: 
	rvalue = MMC_SUCCESS;
	break;
      case 0x0b: 
	return MMC_CRC_ERROR;
      case 0x0d: 
	return MMC_WRITE_ERROR;
      default:
	rvalue = MMC_OTHER_ERROR;
	break;
      }
	
      if(rvalue == MMC_SUCCESS)
	break;
    }
    
    //    while((response = spiSendByte(0xff)) == 0);   // sma sez DANGER!  use some kinda timeout!
    for(j = 0; j < 512; j++){
      if(spiSendByte(0xff)){
	break;
      }
    }
    
    return response;
  }

  command mmcerror_t SD.init(){
    register uint8_t i;

    initSPI();

    CS_HIGH();

    for(i = 0; i < 10; i++)
      spiSendByte(0xff);
    
    return call SD.setIdle();
  }

  command mmcerror_t SD.setIdle(){
    char response;
    CS_LOW();

    // put card in SPI mode
    sendCmd(MMC_GO_IDLE_STATE, 0, 0x95);

    // confirm that card is READY 
    if((response = getResponse()) != 0x01)
      return MMC_INIT_ERROR;

    do{
      CS_HIGH();
      spiSendByte(0xff);
      CS_LOW();
      sendCmd(MMC_SEND_OP_COND, 0x00, 0xff);
    }while((response = getResponse()) == 0x01);

    CS_HIGH();
    spiSendByte(0xff);

    return MMC_SUCCESS;
  }

  // we don't have pin for this one yet; it uses cd pin, which we don't have wired in mock-up
  //  command mmcerror_t detect();

  // change block length to 2^len bytes; default is 512
  command mmcerror_t SD.setBlockLength (const uint16_t len) {
    CS_LOW ();

    sendCmd(MMC_SET_BLOCKLEN, len, 0xff);

    // get response from card, should be 0; so, shouldn't this be 'while'?
    if(getResponse() != 0x00){
      call SD.init();
      sendCmd(MMC_SET_BLOCKLEN, len, 0xff);
      getResponse();
    }

    CS_HIGH ();

    // Send 8 Clock pulses of delay.
    spiSendByte(0xff);

    return MMC_SUCCESS;
  }
    

  command mmcerror_t SD.readSector(uint32_t sector, uint8_t * pBuffer) {
    return call SD.readBlock(sector * 512, 512, pBuffer);
  }

  // see macro in module for writing to a sector instead of an address
  command mmcerror_t SD.readBlock(const uint32_t address, const uint16_t count, uint8_t * buffer){
    register uint16_t i = 0;
    uint8_t rvalue = MMC_RESPONSE_ERROR;

    // Set the block length to read
    if(call SD.setBlockLength(count) == MMC_SUCCESS){   // block length can be set
      CS_LOW ();

      sendCmd(MMC_READ_SINGLE_BLOCK, address, 0xff);
      // Send 8 Clock pulses of delay, check if the MMC acknowledged the read block command
      // it will do this by sending an affirmative response
      // in the R1 format (0x00 is no errors)
      if(getResponse() == 0x00){
	// now look for the data token to signify the start of the data
	if(getXXResponse(MMC_START_DATA_BLOCK_TOKEN) == MMC_START_DATA_BLOCK_TOKEN){

	  // clock the actual data transfer and receive the bytes; spi_read automatically finds the Data Block
	  for (i = 0; i < count; i++)
	    buffer[i] = spiSendByte(0xff);   // is executed with card inserted

	  // get CRC bytes (not really needed by us, but required by MMC)
	  spiSendByte(0xff);
	  spiSendByte(0xff);
	  rvalue = MMC_SUCCESS;
	}
	else{
	  // the data token was never received
	  rvalue = MMC_DATA_TOKEN_ERROR;      // 3
	}
      }
      else{
	// the MMC never acknowledge the read command
	rvalue = MMC_RESPONSE_ERROR;          // 2
      }
    }
    else{
      rvalue = MMC_BLOCK_SET_ERROR;           // 1
    }

    CS_HIGH ();
    spiSendByte(0xff);

    return rvalue;
  }

  command mmcerror_t SD.writeSector(uint32_t sector, uint8_t * pBuffer){
    return call SD.writeBlock(sector * 512, 512, pBuffer);
  }


  command mmcerror_t SD.writeBlock(const uint32_t address, const uint16_t count, uint8_t * buffer){
    register uint16_t i;
    uint8_t rvalue = MMC_RESPONSE_ERROR;         // MMC_SUCCESS;

    // Set the block length to write
    if(call SD.setBlockLength (count) == MMC_SUCCESS){   // block length could be set
      //      call Leds.yellowOn();
      CS_LOW ();
      sendCmd(MMC_WRITE_BLOCK, address, 0xff);

      // check if the MMC acknowledged the write block command
      // it will do this by sending an affirmative response
      // in the R1 format (0x00 is no errors)
      if(getXXResponse(MMC_R1_RESPONSE) == MMC_R1_RESPONSE){
	spiSendByte(0xff);
	// send the data token to signify the start of the data
	spiSendByte(0xfe);
	// clock the actual data transfer and transmitt the bytes

	for(i = 0; i < count; i++)
	  spiSendByte(buffer[i]);            

	// put CRC bytes (not really needed by us, but required by MMC)
	spiSendByte(0xff);
	spiSendByte(0xff);
	// read the data response xxx0<status>1 : status 010: Data accected, status 101: Data
	//   rejected due to a crc error, status 110: Data rejected due to a Write error.
	checkBusy();
	rvalue = MMC_SUCCESS;
      }
      else{
	// the MMC never acknowledge the write command
	rvalue = MMC_RESPONSE_ERROR;   // 2
      }
    }
    else{
      rvalue = MMC_BLOCK_SET_ERROR;   // 1
    }

    CS_HIGH ();
    // Send 8 Clock pulses of delay.
    spiSendByte(0xff);
    //    call Leds.greenOn();
    return rvalue;
  }

  // register read of length len into buffer
  command mmcerror_t SD.readRegister(const uint8_t reg, const uint8_t len, uint8_t * buffer){
    uint8_t uc, rvalue = MMC_TIMEOUT_ERROR;

    if((call SD.setBlockLength (len)) == MMC_SUCCESS){
      CS_LOW ();
      // CRC not used: 0xff as last byte
      sendCmd(reg, 0x000000, 0xff);

      // wait for response
      // in the R1 format (0x00 is no errors)
      if(getResponse() == 0x00){
	if(getXXResponse(0xfe) == 0xfe)
	  for(uc = 0; uc < len; uc++)
	    buffer[uc] = spiSendByte(0xff);  

	// get CRC bytes (not really needed by us, but required by MMC)
	spiSendByte(0xff);
	spiSendByte(0xff);
	rvalue = MMC_SUCCESS;
      }
      else
	rvalue = MMC_RESPONSE_ERROR;

      CS_HIGH ();

      // Send 8 Clock pulses of delay.
      spiSendByte(0xff);
    }
    CS_HIGH ();

    return rvalue;
  } 

  // Read the Card Size from the CSD Register
  // this command is unsupported on sdio-only, like sandisk micro sd cards
  command uint32_t SD.readCardSize(){
    // Read contents of Card Specific Data (CSD)

    uint32_t MMC_CardSize = 0;
    uint16_t i, j, b, response, mmc_C_SIZE;
    uint8_t mmc_READ_BL_LEN, mmc_C_SIZE_MULT;

    CS_LOW ();

    spiSendByte(MMC_READ_CSD);   // CMD 9
    for(i = 0; i < 4; i++)      // Send four dummy bytes
      spiSendByte(0);

    spiSendByte(0xff);   // Send CRC byte

    response = getResponse();

    // data transmission always starts with 0xFE
    b = spiSendByte(0xff);

    if(!response){

      while(b != 0xfe) 
	b = spiSendByte(0xff);
      // bits 127:87
      for(j = 0; j < 5; j++)          // Host must keep the clock running for at
	b = spiSendByte(0xff);


      // 4 bits of READ_BL_LEN
      // bits 84:80
      b = spiSendByte(0xff);  // lower 4 bits of CCC and
      mmc_READ_BL_LEN = b & 0x0f;

      b = spiSendByte(0xff);

      // bits 73:62  C_Size
      // xxCC CCCC CCCC CC
      mmc_C_SIZE = (b & 0x03) << 10;
      b = spiSendByte(0xff);
      mmc_C_SIZE += b << 2;
      b = spiSendByte(0xff);
      mmc_C_SIZE += b >> 6;

      // bits 55:53
      b = spiSendByte(0xff);

      // bits 49:47
      mmc_C_SIZE_MULT = (b & 0x03) << 1;
      b = spiSendByte(0xff);
      mmc_C_SIZE_MULT += b >> 7;

      // bits 41:37
      b = spiSendByte(0xff);

      b = spiSendByte(0xff);

      b = spiSendByte(0xff);

      b = spiSendByte(0xff);

      b = spiSendByte(0xff);

      for(j = 0; j < 4; j++)          // Host must keep the clock running for at
	b = spiSendByte(0xff);  // least Ncr (max = 4 bytes) cycles after
      // the card response is received
      b = spiSendByte(0xff);
      CS_LOW ();

      MMC_CardSize = (mmc_C_SIZE + 1);
      for(i = 2, j = mmc_C_SIZE_MULT + 2; j > 1; j--)
	i <<= 1;
      MMC_CardSize *= i;
      for(i = 2,j = mmc_READ_BL_LEN; j > 1; j--)
	i <<= 1;
      MMC_CardSize *= i;
 
    }
    return MMC_CardSize;
  }

}

