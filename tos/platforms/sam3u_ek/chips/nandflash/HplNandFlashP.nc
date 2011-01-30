/*
 * Copyright (c) 2009 University of Utah
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

#include "HplNandFlash.h"

module HplNandFlashP{
  provides interface HplNandFlash as Hpl;

  uses interface HplSam3uPeripheralClockCntl as HSMC4ClockControl;

  uses interface GeneralIO as NandFlash_CE;
  uses interface GeneralIO as TempPin;
  uses interface GeneralIO as NandFlash_RB;

  uses interface HplSam3uGeneralIOPin as NandFlash_OE;
  uses interface HplSam3uGeneralIOPin as NandFlash_WE;
  uses interface HplSam3uGeneralIOPin as NandFlash_CLE;
  uses interface HplSam3uGeneralIOPin as NandFlash_ALE;

  uses interface HplSam3uGeneralIOPin as NandFlash_Data00;
  uses interface HplSam3uGeneralIOPin as NandFlash_Data01;
  uses interface HplSam3uGeneralIOPin as NandFlash_Data02;
  uses interface HplSam3uGeneralIOPin as NandFlash_Data03;
  uses interface HplSam3uGeneralIOPin as NandFlash_Data04;
  uses interface HplSam3uGeneralIOPin as NandFlash_Data05;
  uses interface HplSam3uGeneralIOPin as NandFlash_Data06;
  uses interface HplSam3uGeneralIOPin as NandFlash_Data07;
  uses interface HplSam3uGeneralIOPin as NandFlash_Data08;
  uses interface HplSam3uGeneralIOPin as NandFlash_Data09;
  uses interface HplSam3uGeneralIOPin as NandFlash_Data10;
  uses interface HplSam3uGeneralIOPin as NandFlash_Data11;
  uses interface HplSam3uGeneralIOPin as NandFlash_Data12;
  uses interface HplSam3uGeneralIOPin as NandFlash_Data13;
  uses interface HplSam3uGeneralIOPin as NandFlash_Data14;
  uses interface HplSam3uGeneralIOPin as NandFlash_Data15;

  uses interface Leds;
  uses interface Draw;

  uses interface Timer<TMilli> as ReadBlockTimer;

}
implementation {

/// Nand flash commands
#define COMMAND_READ_1                  0x00
#define COMMAND_READ_2                  0x30
#define COMMAND_COPYBACK_READ_1         0x00
#define COMMAND_COPYBACK_READ_2         0x35
#define COMMAND_COPYBACK_PROGRAM_1      0x85
#define COMMAND_COPYBACK_PROGRAM_2      0x10
#define COMMAND_RANDOM_OUT              0x05
#define COMMAND_RANDOM_OUT_2            0xE0
#define COMMAND_RANDOM_IN               0x85
#define COMMAND_READID                  0x90
#define COMMAND_WRITE_1                 0x80
#define COMMAND_WRITE_2                 0x10
#define COMMAND_ERASE_1                 0x60
#define COMMAND_ERASE_2                 0xD0
#define COMMAND_STATUS                  0x70
#define COMMAND_RESET                   0xFF

#define COMMAND_READ_A                  0x00
#define COMMAND_READ_C                  0x50

#define STATUS_READY                    (1 << 6)
#define STATUS_ERROR                    (1 << 0)


#define WRITE_COMMAND(commandAddress, u_command) \
    {*((volatile uint8_t *) commandAddress) = (uint8_t) u_command;}
#define WRITE_COMMAND16(commandAddress, u_command) \
    {*((volatile uint16_t *) commandAddress) = (uint16_t) u_command;}
#define WRITE_ADDRESS(addressAddress, address) \
    {*((volatile uint8_t *) addressAddress) = (uint8_t) address;}
#define WRITE_ADDRESS16(addressAddress, address) \
    {*((volatile uint16_t *) addressAddress) = (uint16_t) address;}
#define WRITE_DATA8(dataAddress, data) \
    {*((volatile uint8_t *) dataAddress) = (uint8_t) data;}
#define READ_DATA8(dataAddress) \
    (*((volatile uint8_t *) dataAddress))
#define WRITE_DATA16(dataAddress, data) \
    {*((volatile uint16_t *) dataAddress) = (uint16_t) data;}
#define READ_DATA16(dataAddress) \
    (*((volatile uint16_t *) dataAddress))

/// Number of tries for erasing a block
#define NUMERASETRIES           2
/// Number of tries for writing a block
#define NUMWRITETRIES           2
/// Number of tries for copying a block
#define NUMCOPYTRIES            2

/// Number of NandFlash models inside the list.
#define NandFlashModelList_SIZE         58

#define MODEL(raw)  ((struct NandFlashModel *) raw)

  //------------------------------------------------------------------------------
  //         Exported variables
  //------------------------------------------------------------------------------
  
  //extern const struct NandFlashModel nandFlashModelList[NandFlashModelList_SIZE];

  /// Spare area placement scheme for 256 byte pages.
  const struct NandSpareScheme nandSpareScheme256 = {

    // Bad block marker is at position #5
    5,
    // 3 ecc bytes
    3,
    // Ecc bytes positions
    {0, 1, 2},
    // 4 extra bytes
    4,
    // Extra bytes positions
    {3, 4, 6, 7}
  };

  /// Spare area placement scheme for 512 byte pages.
  const struct NandSpareScheme nandSpareScheme512 = {

    // Bad block marker is at position #5
    5,
    // 6 ecc bytes
    6,
    // Ecc bytes positions
    {0, 1, 2, 3, 6, 7},
    // 8 extra bytes
    8,
    // Extra bytes positions
    {8, 9, 10, 11, 12, 13, 14, 15}
  };

  /// Spare area placement scheme for 2048 byte pages.
  const struct NandSpareScheme nandSpareScheme2048 = {

    // Bad block marker is at position #0
    0,
    // 24 ecc bytes
    24, 
    // Ecc bytes positions
    {40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58,
     59, 60, 61, 62, 63},
    // 38 extra bytes
    38,
    // Extra bytes positions
    {2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21,
     22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39}
  };

  /// List of NandFlash models which can be recognized by the software.
  const struct NandFlashModel nandFlashModelList[NandFlashModelList_SIZE] = {

    // |  ID    | Options                 | Page    | Mo  | Block   |BlkPg   |DevBlk
    {0x6e,   NandFlashModel_DATABUS8,    256,      1,    4,    &nandSpareScheme256},
    {0x64,   NandFlashModel_DATABUS8,    256,      2,    4,    &nandSpareScheme256},
    {0x6b,   NandFlashModel_DATABUS8,    512,      4,    8,    &nandSpareScheme512},
    {0xe8,   NandFlashModel_DATABUS8,    256,      1,    4,    &nandSpareScheme256},
    {0xec,   NandFlashModel_DATABUS8,    256,      1,    4,    &nandSpareScheme256},
    {0xea,   NandFlashModel_DATABUS8,    256,      2,    4,    &nandSpareScheme256},
    {0xd5,   NandFlashModel_DATABUS8,    512,      4,    8,    &nandSpareScheme512},
    {0xe3,   NandFlashModel_DATABUS8,    512,      4,    8,    &nandSpareScheme512},
    {0xe5,   NandFlashModel_DATABUS8,    512,      4,    8,    &nandSpareScheme512},
    {0xd6,   NandFlashModel_DATABUS8,    512,      8,    8,    &nandSpareScheme512},

    {0x39,   NandFlashModel_DATABUS8,    512,      8,    8,    &nandSpareScheme512},
    {0xe6,   NandFlashModel_DATABUS8,    512,      8,    8,    &nandSpareScheme512},
    {0x49,   NandFlashModel_DATABUS16,   512,      8,    8,    &nandSpareScheme512},
    {0x59,   NandFlashModel_DATABUS16,   512,      8,    8,    &nandSpareScheme512},

    {0x33,   NandFlashModel_DATABUS8,    512,     16,   16,    &nandSpareScheme512},
    {0x73,   NandFlashModel_DATABUS8,    512,     16,   16,    &nandSpareScheme512},
    {0x43,   NandFlashModel_DATABUS16,   512,     16,   16,    &nandSpareScheme512},
    {0x53,   NandFlashModel_DATABUS16,   512,     16,   16,    &nandSpareScheme512},
                                                             
    {0x35,   NandFlashModel_DATABUS8,    512,     32,   16,    &nandSpareScheme512},
    {0x75,   NandFlashModel_DATABUS8,    512,     32,   16,    &nandSpareScheme512},
    {0x45,   NandFlashModel_DATABUS16,   512,     32,   16,    &nandSpareScheme512},
    {0x55,   NandFlashModel_DATABUS16,   512,     32,   16,    &nandSpareScheme512},
                                                             
    {0x36,   NandFlashModel_DATABUS8,    512,     64,   16,    &nandSpareScheme512},
    {0x76,   NandFlashModel_DATABUS8,    512,     64,   16,    &nandSpareScheme512},
    {0x46,   NandFlashModel_DATABUS16,   512,     64,   16,    &nandSpareScheme512},
    {0x56,   NandFlashModel_DATABUS16,   512,     64,   16,    &nandSpareScheme512},
                                                             
    {0x78,   NandFlashModel_DATABUS8,    512,    128,   16,    &nandSpareScheme512},
    {0x39,   NandFlashModel_DATABUS8,    512,    128,   16,    &nandSpareScheme512},
    {0x79,   NandFlashModel_DATABUS8,    512,    128,   16,    &nandSpareScheme512},
    {0x72,   NandFlashModel_DATABUS16,   512,    128,   16,    &nandSpareScheme512},
    {0x49,   NandFlashModel_DATABUS16,   512,    128,   16,    &nandSpareScheme512},
    {0x74,   NandFlashModel_DATABUS16,   512,    128,   16,    &nandSpareScheme512},
    {0x59,   NandFlashModel_DATABUS16,   512,    128,   16,    &nandSpareScheme512},
                                                             
    {0x71,   NandFlashModel_DATABUS8,    512,    256,   16,    &nandSpareScheme512},
	
    // Large blocks devices. Parameters must be fetched from the extended I
#define OPTIONS     NandFlashModel_COPYBACK                   
                                                                                          
    {0xA2,   NandFlashModel_DATABUS8  | OPTIONS,   0,     64, 0,  &nandSpareScheme2048},
    {0xF2,   NandFlashModel_DATABUS8  | OPTIONS,   0,     64, 0,  &nandSpareScheme2048},
    {0xB2,   NandFlashModel_DATABUS16 | OPTIONS,   0,     64, 0,  &nandSpareScheme2048},
    {0xC2,   NandFlashModel_DATABUS16 | OPTIONS,   0,     64, 0,  &nandSpareScheme2048},
    
    {0xA1,   NandFlashModel_DATABUS8  | OPTIONS,   0,    128, 0,  &nandSpareScheme2048}, 
    {0xF1,   NandFlashModel_DATABUS8  | OPTIONS,   0,    128, 0,  &nandSpareScheme2048}, 
    {0xB1,   NandFlashModel_DATABUS16 | OPTIONS,   0,    128, 0,  &nandSpareScheme2048},
    {0xC1,   NandFlashModel_DATABUS16 | OPTIONS,   0,    128, 0,  &nandSpareScheme2048},
                                                                  
    {0xAA,   NandFlashModel_DATABUS8  | OPTIONS,   0,    256, 0,  &nandSpareScheme2048},
    {0xDA,   NandFlashModel_DATABUS8  | OPTIONS,   0,    256, 0,   &nandSpareScheme2048},                                              
    {0xBA,   NandFlashModel_DATABUS16 | OPTIONS,   0,    256, 0,  &nandSpareScheme2048},
    {0xCA,   NandFlashModel_DATABUS16 | OPTIONS,   0,    256, 0,  &nandSpareScheme2048},
	                                                                
    {0xAC,   NandFlashModel_DATABUS8  | OPTIONS,   0,    512, 0,  &nandSpareScheme2048}, 
    {0xDC,   NandFlashModel_DATABUS8  | OPTIONS,   0,    512, 0,  &nandSpareScheme2048}, 
    {0xBC,   NandFlashModel_DATABUS16 | OPTIONS,   0,    512, 0,  &nandSpareScheme2048},
    {0xCC,   NandFlashModel_DATABUS16 | OPTIONS,   0,    512, 0,  &nandSpareScheme2048},
                                                                  
    {0xA3,   NandFlashModel_DATABUS8  | OPTIONS,   0,   1024, 0,  &nandSpareScheme2048}, 
    {0xD3,   NandFlashModel_DATABUS8  | OPTIONS,   0,   1024, 0,  &nandSpareScheme2048}, 
    {0xB3,   NandFlashModel_DATABUS16 | OPTIONS,   0,   1024, 0,  &nandSpareScheme2048},
    {0xC3,   NandFlashModel_DATABUS16 | OPTIONS,   0,   1024, 0,  &nandSpareScheme2048},
                                                                  
    {0xA5,   NandFlashModel_DATABUS8  | OPTIONS,   0,   2048, 0,  &nandSpareScheme2048}, 
    {0xD5,   NandFlashModel_DATABUS8  | OPTIONS,   0,   2048, 0,  &nandSpareScheme2048}, 
    {0xB5,   NandFlashModel_DATABUS16 | OPTIONS,   0,   2048, 0,  &nandSpareScheme2048},
    {0xC5,   NandFlashModel_DATABUS16 | OPTIONS,   0,   2048, 0,  &nandSpareScheme2048},
  };

  uint16_t numBlocks;
  uint32_t memSize;
  uint32_t blockSize;
  uint16_t numPagesPerBlock;
  uint16_t pageDataSize;

  void WaitReady(){
    WRITE_COMMAND(BOARD_NF_COMMAND_ADDR, COMMAND_STATUS);
    while ((READ_DATA8(BOARD_NF_DATA_ADDR) & STATUS_READY) != STATUS_READY);
  }

  uint8_t GetDataBusWidth(const struct NandFlashModel *model){
    return (model->options&NandFlashModel_DATABUS16)? 16: 8;
  }

  void WriteColumnAddress(const struct RawNandFlash *raw, uint16_t columnAddress){
    
    uint16_t pageSize = call Hpl.getPageDataSize(MODEL(raw));

    call Draw.drawInt(200, 250, pageSize, 1, COLOR_BLACK);

    /* Check the data bus width of the NandFlash */
    if (GetDataBusWidth(MODEL(raw)) == 16) {
      /* Div 2 is because we address in word and not in byte */
      columnAddress >>= 1;
    }
    while (pageSize > 0) {
      if (GetDataBusWidth(MODEL(raw)) == 16) {
	WRITE_ADDRESS16(BOARD_NF_ADDRESS_ADDR, columnAddress & 0xFF);
      } else {
	WRITE_ADDRESS(BOARD_NF_ADDRESS_ADDR, columnAddress & 0xFF);
      }
      pageSize >>= 8;
      columnAddress >>= 8;
    }
  }

  //------------------------------------------------------------------------------
  /// Sends the row address to the NandFlash chip.
  /// \param raw  Pointer to a RawNandFlash instance.
  /// \param rowAddress  Row address to send.
  //------------------------------------------------------------------------------
  void WriteRowAddress(const struct RawNandFlash *raw, uint32_t rowAddress){

    uint32_t numPages = call Hpl.getDeviceSizeInPages(MODEL(raw));

    while (numPages > 0) {
      if (GetDataBusWidth(MODEL(raw)) == 16) {
	WRITE_ADDRESS16(BOARD_NF_ADDRESS_ADDR, rowAddress & 0xFF);
      } else {
	WRITE_ADDRESS(BOARD_NF_ADDRESS_ADDR, rowAddress & 0xFF);
      }
      numPages >>= 8;
      rowAddress >>= 8;
    }
  }

  void WriteData(const struct RawNandFlash *raw, uint8_t *buffer, uint32_t size){
    uint32_t i;
    // Check the data bus width of the NandFlash
    if (GetDataBusWidth(MODEL(raw)) == 16) {
      uint16_t *buffer16 = (uint16_t *) buffer;
      size >>= 1;
      for(i=0; i < size; i++) {
	call Draw.drawInt(15,50, buffer16[i], 1, COLOR_RED);
	WRITE_DATA16(BOARD_NF_DATA_ADDR, buffer16[i]);
      }
    } else {
      for(i=0; i < size; i++) {
	WRITE_DATA8(BOARD_NF_DATA_ADDR, buffer[i]);
      }
    }
  }

  uint8_t count = 0;

  void ReadData(const struct RawNandFlash *raw, uint8_t *buffer, uint32_t size){
    uint32_t i;
    // Check the chip data bus width

    count ++;

    if (GetDataBusWidth(MODEL(raw)) == 16) {
      uint16_t *buffer16 = (uint16_t *) buffer;

      size >>= 1;

      call Draw.drawInt(200,130, size, 1, COLOR_YELLOW);

      for (i=0 ; i < size ; i++) {
	buffer16[i] = READ_DATA16(BOARD_NF_DATA_ADDR);
	call Draw.drawInt(150,50, buffer16[i] /*READ_DATA16(BOARD_NF_DATA_ADDR)*/, 1, COLOR_BLACK);
      }

      //call Draw.drawInt(100,150, buffer16[0], 1, COLOR_BLACK);
      call Draw.drawInt(200,150, buffer16[3], 1, COLOR_BLACK);
      //call Draw.drawInt(200,150, (uint32_t)buffer16, 1, COLOR_BLACK);

    } else {
      for (i=0; i < size; i++) {
	buffer[i] = READ_DATA8(BOARD_NF_DATA_ADDR);
      }
    }

    call Draw.drawInt(count*15,130, count, 1, COLOR_GREEN);

  }

  uint8_t IsOperationComplete(const struct RawNandFlash *raw){
    uint8_t status;

    WRITE_COMMAND(BOARD_NF_COMMAND_ADDR, COMMAND_STATUS);

    status = READ_DATA8(BOARD_NF_DATA_ADDR);

    if (((status & STATUS_READY) != STATUS_READY) || ((status & STATUS_ERROR) != 0)) {
        return 0;
    }
    return 1;
  }

  uint8_t EraseBlock( const struct RawNandFlash *raw, unsigned short block){
    uint8_t error = 0;
    uint32_t rowAddress;

    // Calculate address used for erase
    rowAddress = block * call Hpl.getBlockSizeInPages(MODEL(raw));

    // Start erase
    //ENABLE_CE(raw);
    // Enable CE
    call NandFlash_CE.clr();

    WRITE_COMMAND(BOARD_NF_COMMAND_ADDR, COMMAND_ERASE_1);
    WriteRowAddress(raw, rowAddress);
    WRITE_COMMAND(BOARD_NF_COMMAND_ADDR, COMMAND_ERASE_2);

    WaitReady();

    if (!IsOperationComplete(raw)) {
      error = NandCommon_ERROR_CANNOTERASE;
    }

    //DISABLE_CE(raw);
    // Disable CE
    call NandFlash_CE.set();

    return error;
    
  }

  uint8_t WritePage(const struct RawNandFlash *raw, uint16_t block, uint16_t page, void *data, void *spare){
    
    uint32_t pageSize = call Hpl.getPageDataSize(MODEL(raw));
    uint32_t spareDataSize = call Hpl.getPageSpareSize(MODEL(raw));
    uint16_t dummyByte;
    uint32_t rowAddress;
    uint8_t error = 0;

    //uint8_t* temp = (uint8_t*)data;

    // Calculate physical address of the page
    rowAddress = block * call Hpl.getBlockSizeInPages(MODEL(raw)) + page;

    // Start write operation
    //ENABLE_CE(raw);
    // Enable CE;
    call NandFlash_CE.clr();

    // Write data area if needed
    if (data) {

      WRITE_COMMAND(BOARD_NF_COMMAND_ADDR, COMMAND_WRITE_1);
      WriteColumnAddress(raw, 0);
      WriteRowAddress(raw, rowAddress);
      WriteData(raw, (uint8_t *) data, pageSize);

      //call Draw.drawInt(50, 50, (uint8_t)temp[0], 1, COLOR_RED);

      // Spare is written here as well since it is more efficient
      if (spare) {
	WriteData(raw, (uint8_t *) spare, spareDataSize);
      }
      else {
	// Note: special case when ECC parity generation. 
	// ECC results are available as soon as the counter reaches the end of the main area.
	// But when reach PageSize for an example, it could not generate last ECC_PR, The 
	// workaround is to receive PageSize+1 word.
	ReadData(raw, (uint8_t *) (&dummyByte), 2);
      }
      WRITE_COMMAND(BOARD_NF_COMMAND_ADDR, COMMAND_WRITE_2);

      WaitReady();

      if (!IsOperationComplete(raw)) {
	error = NandCommon_ERROR_CANNOTWRITE;
      }
    }

    // Write spare area alone if needed
    if (spare && !data) {

      WRITE_COMMAND(BOARD_NF_COMMAND_ADDR, COMMAND_WRITE_1);
      WriteColumnAddress(raw, pageSize);
      WriteRowAddress(raw, rowAddress);
      WriteData(raw, (uint8_t *) spare, spareDataSize);
      WRITE_COMMAND(BOARD_NF_COMMAND_ADDR, COMMAND_WRITE_2);

      WaitReady();
      if (!IsOperationComplete(raw)) {
	error = NandCommon_ERROR_CANNOTWRITE;
      }
    }

    // Disable chip
    //DISABLE_CE(raw);
    // Disable CE
    call NandFlash_CE.set();

    return error;

  }

  uint8_t CopyPage(const struct RawNandFlash *raw, uint16_t sourceBlock, uint16_t sourcePage, uint16_t destBlock, uint16_t destPage){

    uint32_t sourceRow, destRow;
    uint8_t error = 0;
    uint8_t data[NandCommon_MAXPAGEDATASIZE];
    uint8_t spare[NandCommon_MAXPAGESPARESIZE];
    uint16_t numPages = call Hpl.getBlockSizeInPages(MODEL(raw));
    sourceRow = sourceBlock * numPages + sourcePage;
    destRow = destBlock * numPages + destPage;

    if (call Hpl.readPage(raw, sourceBlock, sourcePage, data, spare)) {
      error = NandCommon_ERROR_CANNOTREAD;
    } else if (call Hpl.writePage(raw, destBlock, destPage, data, spare)) {
      error = NandCommon_ERROR_CANNOTWRITE;
    }

    return error;    
  }

  void configureNandFlash(uint8_t busWidth){
    // Take a look at board_memories.h -- NOT CHIP_NAND_CTRL!
    // set clock
    // set smc registers
    volatile smc_setup_t *SETUP = (volatile smc_setup_t *) (0x400E0084 + 0x0);
    smc_setup_t setup = *SETUP;
    volatile smc_pulse_t *PULSE = (volatile smc_pulse_t *) (0x400E0084 + 0x4);
    smc_pulse_t pulse = *PULSE;
    volatile smc_cycle_t *CYCLE = (volatile smc_cycle_t *) (0x400E0084 + 0x8);
    smc_cycle_t cycle = *CYCLE;
    volatile smc_timings_t *TIMINGS = (volatile smc_timings_t *) (0x400E0084 + 0xC);
    smc_timings_t timings = *TIMINGS;
    volatile smc_mode_t *MODE = (volatile smc_mode_t *) (0x400E0084 + 0x10);
    smc_mode_t mode = *MODE;

    // start clock for register access
    call HSMC4ClockControl.disable();
    call HSMC4ClockControl.enable();

    setup.bits.nwe_setup = 0;
    setup.bits.ncs_wr_setup = 1;
    setup.bits.nrd_setup = 0;
    setup.bits.ncs_rd_setup = 1;

    *SETUP = setup;

    pulse.bits.nwe_pulse = 2;
    pulse.bits.ncs_wr_pulse = 3;
    pulse.bits.nrd_pulse = 3;
    pulse.bits.ncs_rd_pulse = 4;

    *PULSE = pulse;

    cycle.bits.nwe_cycle = 4;
    cycle.bits.nrd_cycle = 7;

    *CYCLE = cycle;

    timings.bits.tclr = 1;
    timings.bits.tadl = 2;
    timings.bits.tar = 1;
    timings.bits.trr = 1;
    timings.bits.twb = 2;
    timings.bits.rbnsel = 7;
    timings.bits.nfsel = 1;

    *TIMINGS = timings;

    if(busWidth == 8){
      mode.bits.dbw = 0;
      mode.bits.read_mode = 1;
      mode.bits.write_mode = 1;

      *MODE = mode;

    }else if(busWidth == 16){
      mode.bits.dbw = 1;
      mode.bits.read_mode = 1;
      mode.bits.write_mode = 1;

      *MODE = mode;
      
    }
  }

  void configurePsRam(){
    // TODO: Take a look at board_memories.h -- NOT CHIP_NAND_CTRL!
    // TODO: Does Atmel code work with this disabled?
  }

  void configureNandPins(){

    // Pin setting

    call NandFlash_CE.makeOutput();
    call TempPin.makeInput();
    call NandFlash_RB.makeInput();

    call NandFlash_OE.disablePioControl();
    call NandFlash_WE.disablePioControl();
    call NandFlash_CLE.disablePioControl();
    call NandFlash_ALE.disablePioControl();

    call NandFlash_OE.selectPeripheralA();
    call NandFlash_WE.selectPeripheralA();
    call NandFlash_CLE.selectPeripheralA();
    call NandFlash_ALE.selectPeripheralA();

    call NandFlash_Data00.disablePioControl();
    call NandFlash_Data01.disablePioControl();
    call NandFlash_Data02.disablePioControl();
    call NandFlash_Data03.disablePioControl();
    call NandFlash_Data04.disablePioControl();
    call NandFlash_Data05.disablePioControl();
    call NandFlash_Data06.disablePioControl();
    call NandFlash_Data07.disablePioControl();
    call NandFlash_Data08.disablePioControl();
    call NandFlash_Data09.disablePioControl();
    call NandFlash_Data10.disablePioControl();
    call NandFlash_Data11.disablePioControl();
    call NandFlash_Data12.disablePioControl();
    call NandFlash_Data13.disablePioControl();
    call NandFlash_Data14.disablePioControl();
    call NandFlash_Data15.disablePioControl();

    call NandFlash_Data00.selectPeripheralA();
    call NandFlash_Data01.selectPeripheralA();
    call NandFlash_Data02.selectPeripheralA();
    call NandFlash_Data03.selectPeripheralA();
    call NandFlash_Data04.selectPeripheralA();
    call NandFlash_Data05.selectPeripheralA();
    call NandFlash_Data06.selectPeripheralA();
    call NandFlash_Data07.selectPeripheralA();
    call NandFlash_Data08.selectPeripheralA();
    call NandFlash_Data09.selectPeripheralA();
    call NandFlash_Data10.selectPeripheralA();
    call NandFlash_Data11.selectPeripheralA();
    call NandFlash_Data12.selectPeripheralA();
    call NandFlash_Data13.selectPeripheralA();
    call NandFlash_Data14.selectPeripheralA();
    call NandFlash_Data15.selectPeripheralB(); // PB6
  }

  command uint8_t Hpl.hasSmallBlocks(const struct NandFlashModel *model){
    return (model->pageSizeInBytes <= 512 )? 1: 0;
  }

  //------------------------------------------------------------------------------
  /// Returns the size of the data area of a page in bytes.
  /// \param model  Pointer to a NandFlashModel instance.
  //------------------------------------------------------------------------------
  command uint16_t Hpl.getPageDataSize(const struct NandFlashModel *model){
    return model->pageSizeInBytes;
  }

  //------------------------------------------------------------------------------
  /// Returns the size of the spare area of a page in bytes.
  /// \param model  Pointer to a NandFlashModel instance.
  //------------------------------------------------------------------------------
  command uint8_t Hpl.getPageSpareSize(const struct NandFlashModel *model){
    return (model->pageSizeInBytes>>5); /// Spare size is 16/512 of data size
  }

  command void Hpl.init(struct RawNandFlash *HplNand, const struct NandFlashModel *model, uint32_t commandAddr, uint32_t addressAddr, uint32_t dataAddr){
    uint32_t chipId;
    uint8_t error;
    uint8_t busWidth = 16;

    configureNandFlash(busWidth);
    configureNandPins();

    HplNand -> commandAddress = commandAddr;
    HplNand -> addressAddress = addressAddr;
    HplNand -> dataAddress = dataAddr;

    call Hpl.reset();

    if(!model){
      chipId = call Hpl.readId();
      error = call Hpl.findNandModel(nandFlashModelList, NandFlashModelList_SIZE, &(HplNand->model), chipId);
    }else{
      HplNand -> model = *model;
    }

    if(!error){
    } else {
    }

    busWidth = 0;
    busWidth = GetDataBusWidth(MODEL(HplNand));
    configureNandFlash(busWidth);

    memSize = call Hpl.getDeviceSizeInBytes(MODEL(HplNand));
    blockSize = call Hpl.getBlockSizeInBytes(MODEL(HplNand));
    numBlocks = call Hpl.getDeviceSizeInBlocks(MODEL(HplNand));
    pageDataSize = call Hpl.getPageDataSize(MODEL(HplNand));
    numPagesPerBlock = call Hpl.getBlockSizeInPages(MODEL(HplNand));    

    call Draw.drawInt(150, 20, busWidth, 1, COLOR_BLACK);
    call Draw.drawInt(150, 40, pageDataSize, 1, COLOR_BLACK);
    call Draw.drawInt(150, 60, memSize, 1, COLOR_BLACK);
    call Draw.drawInt(150, 80, numPagesPerBlock, 1, COLOR_BLACK);

  }

  command uint8_t Hpl.findNandModel(const struct NandFlashModel *modelList, uint8_t size, struct NandFlashModel *model, uint32_t chipId){

    uint8_t i, found = 0;

    //volatile smc_cfg_t *CFG = (volatile smc_cfg_t *) (0x400E0000);
    //smc_cfg_t cfg = *CFG;

    uint8_t id2 = (uint8_t)(chipId>>8);
    uint8_t id4 = (uint8_t)(chipId>>24);

    //call Draw.drawInt(100, 60, chipId, 1, COLOR_YELLOW);
    //call Draw.drawInt(100, 80, id2, 1, COLOR_YELLOW);
    
    for(i=0; i<size; i++) {
      if(modelList[i].deviceId == id2) {
	found = 1;

	if(model) {

	  memcpy(model, &modelList[i], sizeof(struct NandFlashModel));

	  if(model->blockSizeInKBytes == 0 || model->pageSizeInBytes == 0) {
	    //TRACE_DEBUG("Fetch from ID4(0x%.2x):\r\n", id4);
	    /// Fetch from the extended ID4
	    /// ID4 D5  D4 BlockSize || D1  D0  PageSize
	    ///     0   0   64K      || 0   0   1K
	    ///     0   1   128K     || 0   1   2K
	    ///     1   0   256K     || 1   0   4K
	    ///     1   1   512K     || 1   1   8k
	    switch(id4 & 0x03) {
	    case 0x00: model->pageSizeInBytes = 1024; break;
	    case 0x01: model->pageSizeInBytes = 2048; break;
	    case 0x02: model->pageSizeInBytes = 4096; break;
	    case 0x03: model->pageSizeInBytes = 8192; break;
	    }
	    switch(id4 & 0x30) {
	    case 0x00: model->blockSizeInKBytes = 64;  break;
	    case 0x10: model->blockSizeInKBytes = 128; break;
	    case 0x20: model->blockSizeInKBytes = 256; break;
	    case 0x30: model->blockSizeInKBytes = 512; break;
	    }
	  }

	  /*
	  switch(model->pageSizeInBytes) {
	  case 1024: pageSize = AT91C_HSMC4_PAGESIZE_1056_Bytes; break;
	  case 2048: pageSize = AT91C_HSMC4_PAGESIZE_2112_Bytes; break;
	  case 4096: pageSize = AT91C_HSMC4_PAGESIZE_4224_Bytes; break;
	  default: ;//TRACE_ERROR("Unsupportted page size for NAND Flash Controller\n\r");
	  }
	  // This part sets the SMC registers? this is it?

	  cfg.bits.pagesize = pageSize;
	  cfg.bits.dtomul = 7;
	  cfg.bits.edgectrl = 1;
	  cfg.bits.dtocyc = 0xF;
	  cfg.bits.rspare = 1;

	  *CFG = cfg;
	  //HSMC4_SetMode(pageSize | AT91C_HSMC4_DTOMUL_1048576 | AT91C_HSMC4_EDGECTRL | AT91C_HSMC4_DTOCYC | AT91C_HSMC4_RSPARE); // ?????????????
	  */
	}
	break;
      }
    }

    // Check if chip has been detected
    if (found) {
      return 0;
    }
    else {
      return NandCommon_ERROR_UNKNOWNMODEL;
    }
  }

  command void Hpl.reset(){
    /*
      1. Enable CE
      2. Write reset command
      3. wait for ready
      4. Disable CE
     */

    // Enable CE
    call NandFlash_CE.clr();

    WRITE_COMMAND16(BOARD_NF_COMMAND_ADDR, COMMAND_RESET);
    //WRTIE_COMMAND(BOARD_NF_COMMAND_ADDR, COMMAND_RESET);
    WaitReady();
    // Disable CE

    call NandFlash_CE.set();
  }

  command uint32_t Hpl.readId(){
    uint32_t chipId;

    // enable CE 
    call NandFlash_CE.clr();

    WRITE_COMMAND16(BOARD_NF_COMMAND_ADDR, COMMAND_READID);
    //WRITE_COMMAND(BOARD_NF_COMMAND_ADDR, COMMAND_READID);
    WRITE_ADDRESS(BOARD_NF_ADDRESS_ADDR, 0);

    chipId  = READ_DATA8(BOARD_NF_DATA_ADDR);
    chipId |= READ_DATA8(BOARD_NF_DATA_ADDR) << 8;
    chipId |= READ_DATA8(BOARD_NF_DATA_ADDR) << 16;
    chipId |= READ_DATA8(BOARD_NF_DATA_ADDR) << 24;

    // Disable CE 
    call NandFlash_CE.set();

    return chipId;
  }

  command uint16_t Hpl.getDeviceSizeInBlocks(const struct NandFlashModel * model){
    return ((1024) / model->blockSizeInKBytes) * model->deviceSizeInMegaBytes;
  }

  command uint32_t Hpl.getDeviceSizeInPages(const struct NandFlashModel *model){
    return (uint32_t) call Hpl.getDeviceSizeInBlocks(model) * call Hpl.getBlockSizeInPages(model);
  }

  command uint8_t Hpl.eraseBlock(const struct RawNandFlash *raw, uint16_t block){

    uint8_t numTries = NUMERASETRIES;

    while (numTries > 0) {

        if (!EraseBlock(raw, block)) {

            return 0;
        }
        numTries--;
    }

    return NandCommon_ERROR_BADBLOCK;

  }

  command uint16_t Hpl.getBlockSizeInPages(const struct NandFlashModel *model){
    return model->blockSizeInKBytes * 1024 / model->pageSizeInBytes;
  }

  command uint8_t Hpl.readPage(const struct RawNandFlash *raw, uint16_t block, uint16_t page, void *data, void *spare){

    uint32_t colAddress;
    uint32_t rowAddress;
    uint8_t hasSmallBlocks;
    uint32_t pageSpareSize;

    hasSmallBlocks = call Hpl.hasSmallBlocks(MODEL(raw));
    pageSpareSize = call Hpl.getPageSpareSize(MODEL(raw));

    // Calculate actual address of the page
    rowAddress = (uint32_t) block * numPagesPerBlock /*call Hpl.getBlockSizeInPages(MODEL(raw))*/ + page;

    // Start operation
    //ENABLE_CE(raw);
    // Enable CE
    call NandFlash_CE.clr();

    if (data) {
      colAddress = 0;
    } else {
      // to read spare area in sequential access
      colAddress = pageDataSize;
    }

    // Use either small blocks or large blocks data area read
    if (hasSmallBlocks) {
      WRITE_COMMAND(BOARD_NF_COMMAND_ADDR, COMMAND_READ_A);
      WriteColumnAddress(raw, colAddress);
      WriteRowAddress(raw, rowAddress);
    } else {
      WRITE_COMMAND(BOARD_NF_COMMAND_ADDR, COMMAND_READ_1);
      WriteColumnAddress(raw, colAddress);
      WriteRowAddress(raw, rowAddress);
      WRITE_COMMAND(BOARD_NF_COMMAND_ADDR, COMMAND_READ_2);
    }

    // Wait for the nand to be ready
    WaitReady();

    //pageDataSize = call Hpl.getPageDataSize(MODEL(raw));
    call Draw.drawInt(200, 220, colAddress, 1, COLOR_BLUE);
    call Draw.drawInt(100, 220, pageDataSize, 1, COLOR_BLUE);
    call Draw.drawInt(rowAddress*15, 200, rowAddress, 1, COLOR_BLUE);

    // Read data area if needed
    if (data) {

      WRITE_COMMAND(BOARD_NF_COMMAND_ADDR, COMMAND_READ_1);

      if(pageDataSize != 2048){
	call Draw.drawInt(200, 240, page, 1, COLOR_GREEN);
      }

      ReadData(raw, (uint8_t *) data, pageDataSize);

      if (spare) {
	//call Leds.led2Toggle();
	ReadData(raw, (uint8_t *) spare, pageSpareSize);
      }
    }
    else {
      // Read spare area only
      WRITE_COMMAND(BOARD_NF_COMMAND_ADDR, COMMAND_READ_1);
      ReadData(raw, (uint8_t *) spare, pageSpareSize);
    }


    // Disable CE
    //DISABLE_CE(raw);
    // Disable CE
    call NandFlash_CE.set();

    return 0;
  }

  //------------------------------------------------------------------------------
  /// Reads the bad block marker inside a spare area buffer using the provided
  /// scheme.
  /// \param scheme  Pointer to a NandSpareScheme instance.
  /// \param spare  Spare area buffer.
  /// \param marker  Pointer to the variable to store the bad block marker.
  //------------------------------------------------------------------------------
  command void Hpl.readBadBlockMarker(const struct NandSpareScheme *scheme, const uint8_t *spare, uint8_t *marker){
    *marker = spare[scheme->badBlockMarkerPosition];
  }

  //------------------------------------------------------------------------------
  /// Modifies the bad block marker inside a spare area, using the given scheme.
  /// \param scheme  Pointer to a NandSpareScheme instance.
  /// \param spare  Spare area buffer.
  /// \param marker  Bad block marker to write.
  //------------------------------------------------------------------------------
  command void Hpl.writeBadBlockMarker(const struct NandSpareScheme *scheme, uint8_t *spare, uint8_t marker){
    spare[scheme->badBlockMarkerPosition] = marker;
  }

  command uint32_t Hpl.getDeviceSizeInBytes(const struct NandFlashModel *model){
    return ((uint32_t) model->deviceSizeInMegaBytes) << 20;
  }

  command uint32_t Hpl.getBlockSizeInBytes(const struct NandFlashModel *model){
    return (model->blockSizeInKBytes *1024);
  }

  command uint8_t Hpl.writePage(const struct RawNandFlash *raw, uint16_t block, uint16_t page, void *data, void *spare){
    uint8_t numTries = NUMWRITETRIES;
    while (numTries > 0) {
      if (!WritePage(raw, block, page, data, spare)) {
	return 0;
      }
      numTries--;
    }
    return NandCommon_ERROR_BADBLOCK;
  }

  command uint8_t Hpl.copyPage(const struct RawNandFlash *raw, uint16_t sourceBlock, uint16_t sourcePage, uint16_t destBlock, uint16_t destPage){
    uint8_t numTries = NUMCOPYTRIES;
    while (numTries) {
      if (!CopyPage(raw, sourceBlock, sourcePage, destBlock, destPage)) {
	return 0;
      }
      numTries--;
    }
    return NandCommon_ERROR_BADBLOCK;
  }

  command uint8_t Hpl.copyBlock(const struct RawNandFlash *raw, uint16_t sourceBlock, uint16_t destBlock){
    uint32_t i;
    uint16_t numPages = call Hpl.getBlockSizeInPages(MODEL(raw));
    // Copy all pages
    for (i=0; i < numPages; i++) {
      if (call Hpl.copyPage(raw, sourceBlock, i, destBlock, i)) {
	return NandCommon_ERROR_BADBLOCK;
      }
    }
    return 0;
  }

  uint16_t totalReadFromBlock = 0;
  uint16_t readBlock = 0;
  void* readData;
  const struct RawNandFlash saveRaw;

  void readBlockTask(){

    uint8_t error;

    call Draw.fill(COLOR_WHITE);

    error = call Hpl.readPage(&saveRaw, readBlock, totalReadFromBlock, readData, 0);//ECC(skipBlock), block, i, data, 0);
    totalReadFromBlock ++;

    if (error) {
      //call Leds.led0Toggle();
      return;
    }else if(totalReadFromBlock < numPagesPerBlock){
      //call Draw.drawInt(totalReadFromBlock*15, 170, totalReadFromBlock, 1, COLOR_BLUE);
      //call Draw.drawInt(200, 185, numPagesPerBlock, 1, COLOR_BLUE);
      //readData = (void *) ((uint8_t *) readData + pageDataSize);
      readBlockTask();
      //call ReadBlockTimer.startOneShot(5);
    }else{
      call Leds.led2Toggle();
    }
    
  }

  command uint8_t Hpl.readBlock(const struct RawNandFlash *raw, uint16_t block, void *data){
    //uint16_t i, error;
    //volatile twi_cr_t* CR = (volatile twi_cr_t *) (TWI1_BASE_ADDR + 0x0);

    uint8_t* data_local = (uint8_t*) data;

    totalReadFromBlock = 0;

    memcpy((void*)&saveRaw, (void*)raw, sizeof(struct RawNandFlash));

    readBlock = block;
    readData = data;

    call Draw.drawInt(50,150, data_local[0], 1, COLOR_BLACK);
    call Draw.drawInt(100,150, data_local[1], 1, COLOR_BLACK);
    call Draw.drawInt(150,150, data_local[2], 1, COLOR_BLACK);
    call Draw.drawInt(200,150, data_local[3], 1, COLOR_BLACK);

    readBlockTask();

    return 0;
  }

  command uint8_t Hpl.writeBlock(const struct RawNandFlash *raw, uint16_t block, void *data){
    uint8_t error, i;

    for(i=0; i<numPagesPerBlock; i++){
      call Draw.fill(COLOR_YELLOW);
      error = call Hpl.writePage(raw, block, i, data, 0);
      data = (void *) ((uint8_t *) data + pageDataSize);
    }

    return 0;
  }


  event void ReadBlockTimer.fired(){
    readBlockTask();
  }
}
