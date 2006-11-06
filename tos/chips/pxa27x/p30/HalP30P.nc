/* 
 * Author:		Josh Herbach
 * Revision:	1.0
 * Date:		09/02/2005
 */
module HalP30P {
  provides interface Init;
  provides interface Flash; //does not allow writing into FLASH_PROTECTED_REGION
  uses interface HplP30;
}
implementation {
  
#include <P30.h>

  enum {
    FLASH_STATE_READ_INACTIVE, 
    FLASH_STATE_PROGRAM,
    FLASH_STATE_ERASE,
    FLASH_STATE_READ_ACTIVE
  };

  uint8_t FlashPartitionState[FLASH_PARTITION_COUNT];
  uint8_t init = 0, programBufferSupported = 2, currBlock = 0;
  
  command error_t Init.init() {
    int i = 0;
    if(init != 0)
      return SUCCESS;
    init = 1;
    for(i = 0; i < FLASH_PARTITION_COUNT; i++) 
      FlashPartitionState[i] = FLASH_STATE_READ_INACTIVE;
    
    return SUCCESS;
  }
  
  uint16_t writeHelper(uint32_t addr, uint8_t* data, uint32_t numBytes,
		       uint8_t prebyte, uint8_t postbyte){
    uint32_t i = 0, j = 0, k = 0;
    error_t status;
    uint16_t buffer[FLASH_PROGRAM_BUFFER_SIZE];
    
    if(numBytes == 0)
      return FAIL;
    
    if(addr % 2 == 1){
      status = call HplP30.progWord(addr - 1, prebyte | (data[i] << 8));
      i++;
      if(status != SUCCESS)
	return FAIL;
    }
    
    if(addr % 2 == numBytes % 2){
      if(programBufferSupported == 1)
	for(; i < numBytes; i = k){
	  for(j = 0, k = i; k < numBytes && 
		j < FLASH_PROGRAM_BUFFER_SIZE; j++, k+=2)
	    buffer[j] = data[k] | (data[k + 1] << 8);
	  status = call HplP30.progBuffer(addr + i, buffer, j);
	  if(status != SUCCESS)
	    return FAIL;
	}
      else
	for(; i < numBytes; i+=2){
	  status = call HplP30.progWord(addr + i, (data[i + 1] << 8) | data[i]);
	  if(status != SUCCESS)
	    return FAIL;
	}
    }
    else{
      if(programBufferSupported == 1)
	for(; i < numBytes - 1; i = k){
	  for(j = 0, k = i; k < numBytes - 1 && 
		j < FLASH_PROGRAM_BUFFER_SIZE; j++, k+=2)
	    buffer[j] = data[k] | (data[k + 1] << 8);
	  status = call HplP30.progBuffer(addr + i, buffer, j);
	  if(status != SUCCESS)
	    return FAIL;
	}
      else
	for(; i < numBytes - 1; i+=2){
	  status = call HplP30.progWord(addr + i, (data[i + 1] << 8) | data[i]);
	  if(status != SUCCESS)
	    return FAIL;
	}
      status = call HplP30.progWord(addr + i, data[i] | (postbyte << 8));
      if(status != SUCCESS)
	return FAIL;
    }
    return SUCCESS;
  }
  
  void writeExitHelper(uint32_t addr, uint32_t numBytes){
    uint32_t i = 0;
    for(i = addr / FLASH_PARTITION_SIZE;
	i < (numBytes + addr) / FLASH_PARTITION_SIZE;
	i++)
      FlashPartitionState[i] = FLASH_STATE_READ_INACTIVE;
  }
  
  command error_t Flash.write(uint32_t addr, uint8_t* data, uint32_t numBytes) {
    uint32_t i;
    uint16_t status;
    uint8_t blocklen;
    uint32_t blockAddr = (addr / P30_BLOCK_SIZE) * P30_BLOCK_SIZE;
    
    if(addr + numBytes > 0x02000000) //not in the flash memory space
      return FAIL;
    if(addr < FLASH_PROTECTED_REGION)
      return FAIL;
    
    
    for(i = 0; i < FLASH_PARTITION_COUNT; i++)
      if(i != addr / FLASH_PARTITION_SIZE &&
	 FlashPartitionState[i] != FLASH_STATE_READ_INACTIVE &&
	 FlashPartitionState[i] != FLASH_STATE_READ_ACTIVE)
	return FAIL;
    
    
    for(i = addr / FLASH_PARTITION_SIZE;
	i < (numBytes + addr) / FLASH_PARTITION_SIZE;
	i++)
      if(FlashPartitionState[i] != FLASH_STATE_READ_INACTIVE)
	return FAIL;
    
    for(i = addr / FLASH_PARTITION_SIZE;
	i < (numBytes + addr) / FLASH_PARTITION_SIZE;
	i++)
      FlashPartitionState[i] = FLASH_STATE_PROGRAM;

    atomic{
      for(blocklen = 0, i = blockAddr;
	  i < addr + numBytes;
	  i += P30_BLOCK_SIZE, blocklen++)
	call HplP30.blkUnlock(i); //unlock(i);
      
      if(programBufferSupported == 2){
	uint16_t testBuf[1];
	
	if(addr % 2 == 0){
	  testBuf[0] = data[0] | ((*((uint8_t *)(addr + 1))) << 8);
	  status = call HplP30.progBuffer(addr, testBuf, 1);
	}
	else{
	  testBuf[0] = *((uint8_t *)(addr - 1)) | (data[0] << 8);
	  status = call HplP30.progBuffer(addr - 1, testBuf, 1);
	}      
	if(status != SUCCESS)
	  programBufferSupported = 0;
	else 
	  programBufferSupported = 1;
      }
    }
    if(blocklen == 1){
      atomic status = writeHelper(addr,data,numBytes,0xFF,0xFF);
      if(status == FAIL){
	writeExitHelper(addr, numBytes);
	return FAIL;
      }
    }
    else{
      uint32_t bytesLeft = numBytes;
      atomic status = writeHelper(addr,data, blockAddr + P30_BLOCK_SIZE - addr,0xFF,0xFF);
      if(status == FAIL){
	writeExitHelper(addr, numBytes);
	return FAIL;
      }
      bytesLeft = numBytes - (P30_BLOCK_SIZE - (addr - blockAddr));
      for(i = 1; i < blocklen - 1; i++){
	atomic status = writeHelper(blockAddr + i * P30_BLOCK_SIZE, (uint8_t *)(data + numBytes - bytesLeft),
				    P30_BLOCK_SIZE,0xFF,0xFF);
	bytesLeft -= P30_BLOCK_SIZE;
	if(status == FAIL){
	  writeExitHelper(addr, numBytes);
	  return FAIL;
	}
      }
      atomic status = writeHelper(blockAddr + i * P30_BLOCK_SIZE, data + (numBytes - bytesLeft), bytesLeft, 0xFF,0xFF);
      if(status == FAIL){
	writeExitHelper(addr, numBytes);
	return FAIL;
      }
    }
    
    writeExitHelper(addr, numBytes);
    return SUCCESS;
  }
  
  command error_t Flash.erase(uint32_t addr){
    uint16_t status, i;
    uint32_t j;
    
    if(addr > 0x02000000) //not in the flash memory space
      return FAIL;
    if(addr < FLASH_PROTECTED_REGION)
      return FAIL;
    
    addr = (addr / P30_BLOCK_SIZE) * P30_BLOCK_SIZE;
    
    for(i = 0; i < FLASH_PARTITION_COUNT; i++)
      if(i != addr / FLASH_PARTITION_SIZE &&
	 FlashPartitionState[i] != FLASH_STATE_READ_INACTIVE &&
	 FlashPartitionState[i] != FLASH_STATE_READ_ACTIVE)
	return FAIL;
    
    if(FlashPartitionState[addr / FLASH_PARTITION_SIZE] != FLASH_STATE_READ_INACTIVE)
      return FAIL;
    
    FlashPartitionState[addr / FLASH_PARTITION_SIZE] = FLASH_STATE_ERASE;
    
    for(j = 0; j < P30_BLOCK_SIZE; j++){
      uint32_t tempCheck = *(uint32_t *)(addr + j);
      if(tempCheck != 0xFFFFFFFF)
	break;
      if(j == P30_BLOCK_SIZE - 1){
	FlashPartitionState[addr / FLASH_PARTITION_SIZE] = FLASH_STATE_READ_INACTIVE;
	return SUCCESS;
      }
    }
    atomic{
      call HplP30.blkUnlock(addr);
      //      status = eraseFlash(addr);
      status = call HplP30.blkErase(addr);
    }
    FlashPartitionState[addr / FLASH_PARTITION_SIZE] = FLASH_STATE_READ_INACTIVE;
    if(status != SUCCESS)
      return FAIL;
    
    return SUCCESS;
  }

  // WARNING: Check the endien of this
  command error_t Flash.read(uint32_t addr, uint8_t* buf, uint32_t len) {
    error_t status;

    uint8_t databyte;
    /*
    uint16_t dataword;
    
    while(len > 1) {
      atomic {
	status = call HplP30.readWordBurst(addr, &dataword);
      }
      if(status != SUCCESS)
	return FAIL;
      
      *((uint16_t*) buf) = dataword;

      addr += 2;
      buf += 2;
      len -= 2;
    }

    if(len == 1) {
      atomic {
	status = call HplP30.readWordBurst(addr, &dataword);
      }
      if(status != SUCCESS)
	return FAIL;

      *buf = (uint8_t) dataword;
    }
    */

    while(len > 0) {
      atomic {
	status = call HplP30.readByteBurst(addr, &databyte);
      }
      if(status != SUCCESS)
	return FAIL;
      
      *buf = databyte;

      addr += 1;
      buf += 1;
      len -= 1;
    }

    return SUCCESS;
  }
}
