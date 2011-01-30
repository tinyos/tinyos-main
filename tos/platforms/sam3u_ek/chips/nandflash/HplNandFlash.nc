/*
 * Copyright (c) 2010 Johns Hopkins University
 *
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

#include <HplNandFlash.h>

interface HplNandFlash{
  //command void writeColumnAddress();
  //command void writeRowAddress();
  //command void isOperationComplete();
  //command void writeData();
  //command void readData();

  //command void eraseBlock_i(); // internal functions 
  //command void writePage_i(); // internal functions
  //command void copyPage_i(); // internal functions

  command void init(struct RawNandFlash *HplNand, const struct NandFlashModel *model, uint32_t commandAddr, uint32_t addressAddr, uint32_t dataAddr);
  command uint8_t findNandModel(const struct NandFlashModel *modelList, uint8_t size, struct NandFlashModel *model, uint32_t chipId);
  command void reset();
  command uint32_t readId();
  command uint8_t eraseBlock(const struct RawNandFlash *raw, uint16_t block);
  command uint8_t readPage(const struct RawNandFlash *raw, uint16_t block, uint16_t page, void *data, void *spare);
  command uint8_t writePage(const struct RawNandFlash *raw, uint16_t block, uint16_t page, void *data, void *spare);
  command uint8_t copyPage(const struct RawNandFlash *raw, uint16_t sourceBlock, uint16_t sourcePage, uint16_t destBlock, uint16_t destPage);
  command uint8_t copyBlock(const struct RawNandFlash *raw, uint16_t sourceBlock, uint16_t destBlock);



  command uint16_t getPageDataSize(const struct NandFlashModel *model);
  command uint32_t getDeviceSizeInPages(const struct NandFlashModel *model);
  command uint16_t getBlockSizeInPages(const struct NandFlashModel *model);
  command uint8_t getPageSpareSize(const struct NandFlashModel *model);
  command uint8_t hasSmallBlocks(const struct NandFlashModel *model);
  command uint16_t getDeviceSizeInBlocks(const struct NandFlashModel * model);
  command void readBadBlockMarker(const struct NandSpareScheme *scheme, const uint8_t *spare, uint8_t *marker);
  command void writeBadBlockMarker(const struct NandSpareScheme *scheme, uint8_t *spare, uint8_t marker);
  command uint32_t getDeviceSizeInBytes(const struct NandFlashModel *model);
  command uint32_t getBlockSizeInBytes(const struct NandFlashModel *model);
  command uint8_t readBlock(const struct RawNandFlash *raw, uint16_t block, void *data);
  command uint8_t writeBlock(const struct RawNandFlash *raw, uint16_t block, void *data);
}
