/*
 * Copyright (c) 2008 Johns Hopkins University.
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
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 * @author Razvan Musaloiu-E. <razvanm@cs.jhu.edu>
 */
 
#include SLCS_TYPES_FILE
#include "thread.h"

module DynamicLoaderP
{
  provides {
    interface Init;
    interface DynamicLoader;
  }
  
  uses {
    interface Leds;
    interface BlockRead as ImageRead[uint8_t id];
    interface DynamicThread;
    interface ThreadNotification[uint8_t id];
    interface ThreadScheduler;
    interface ReferenceCounter;
    interface PMManager;
#ifndef DISABLE_LOADER_USERBUTTON
    interface UserButton;
#endif
  }
}

implementation
{ 
  uint8_t *code;   // Points to first byte of the program code in the internal flash
  uint8_t *tablesMemory;
  void *gVarMemory;
  struct prog_desc prog_desc;
  init_block_t *proc;
  
  uint16_t codePtr;   // Records what code has been copied to the internal flash
  uint16_t nextAddr;
  uint8_t *nextTask_chain;   // Used to update the next patching address in a chain
  
  uint8_t readSource;   // Loads from flash or memory
  uint16_t readSourceOffset;   // If loading from memory, then this is effectively the passed-in memory address  
  error_t retError = FAIL;
  tosthread_t handler;
  uint16_t threadCodeSizes[TOSTHREAD_MAX_NUM_THREADS];
  uint16_t codeFirstAddrs[TOSTHREAD_MAX_NUM_THREADS];
  
  async event void ThreadNotification.justCreated[uint8_t id]()
  {
    thread_t *t = call ThreadScheduler.threadInfo(id);
    if(t->init_block != NULL) {
      call ReferenceCounter.increment(&(t->init_block->thread_counter));
    }
  }
  
  async event void ThreadNotification.aboutToDestroy[uint8_t id]()
  {
    thread_t *t = call ThreadScheduler.threadInfo(id);
    if(t->init_block != NULL) {
      call ReferenceCounter.decrement(&(t->init_block->thread_counter));
    }
  }

  task void loadDoneTask()
  {
    if (retError != SUCCESS)
      handler = TOSTHREAD_INVALID_THREAD_ID;

    if (readSource == READSOURCE_MEMORY) {
      signal DynamicLoader.loadFromMemoryDone(((void *)readSourceOffset), handler, retError);
    } else {
      signal DynamicLoader.loadFromFlashDone(readSource, handler, retError);
    }
  }
    
  void initProgDesc()
  {
    prog_desc.main_addr = 0;
    prog_desc.alloc_count = 0;
    prog_desc.g_reloc_count = 0;
    prog_desc.l_reloc_count = 0;
    prog_desc.code_count = 0;
    prog_desc.patch_table_count = 0;

    prog_desc.loading_stage = 0;
    codePtr = 0;
  }

  void errorHandler()
  {
    call Leds.set(7);
    
    if (tablesMemory != NULL) { free(tablesMemory); tablesMemory = NULL; }
    if (gVarMemory != NULL) { free(gVarMemory); gVarMemory = NULL; }
    if (proc != NULL) { free(proc); proc = NULL; }
    initProgDesc();
    
    retError = FAIL;
    post loadDoneTask();
  }

  void run_proc(void *arg)
  {
    init_block_t* curProc = arg;
    thread_t* t = call ThreadScheduler.currentThreadInfo();
    t->init_block = curProc;
    
    (*(curProc->init_ptr))(curProc->init_arg);
    call ReferenceCounter.waitOnValue(&(curProc->thread_counter), 0);
    
    call PMManager.release(codeFirstAddrs[t->id], threadCodeSizes[t->id]);
    codeFirstAddrs[t->id] = 0;
    threadCodeSizes[t->id] = 0;
    if (curProc->globals != NULL) {
      free(curProc->globals);
    }
    free(curProc);
  }

  task void start_prog()
  {
    free(tablesMemory);
    proc = malloc(sizeof(init_block_t));
    proc->globals = gVarMemory;
    proc->init_ptr = (void *)((uint16_t)code + prog_desc.main_addr);
    proc->init_arg = NULL;
    call ReferenceCounter.init( &(proc->thread_counter) );
    
    if (call DynamicThread.create(&handler, run_proc, proc, 200) == SUCCESS) {  
      codeFirstAddrs[handler] = (uint16_t)code;
      threadCodeSizes[handler] = prog_desc.code_count;
      retError = SUCCESS;
      post loadDoneTask();
    } else {
      retError = FAIL;
      post loadDoneTask();
      if (proc->globals != NULL) {
        free(proc->globals);
      }
      free(proc);
    }
    
    initProgDesc();
  }

  // Gets write access to the internal flash
  void eeprom_w()
  {
    FCTL2 = FWKEY + FSSEL1 + FN2;   // selects SMCLK and divides it by 4
    FCTL3 = FWKEY;   // enables the writing/erasing by clearing the LOCK bit
    FCTL1 = FWKEY + WRT;   // enables the writing
  }

  // Gets read-only access to the internal flash
  void eeprom_r()
  {
    FCTL1 = FWKEY;   // Clear WRT bit
    FCTL3 = FWKEY + LOCK;   // disabling the writing/erasing
  }

  // Calculates where should the code be placed in the internal flash
  /*
  uint16_t eeprom_code_addr()
  {
    uint16_t addr;
    
    addr = (((prog_desc.code_count - 1) / 512) + 1) * 512;   // Spaces needed for the code
    addr = 0xFFFF - 512 - addr + 1;   // The 1 is to align the code
    
    return addr; 
  }
  */

  // Loads program image meta data
  void loader_metaData()
  {
    prog_desc.patch_table_count = prog_desc.alloc_count +
                                  prog_desc.g_reloc_count +
                                  prog_desc.l_reloc_count;
    prog_desc.code_offset = sizeof(prog_desc.main_addr) +
                            sizeof(prog_desc.alloc_count) +
                            sizeof(prog_desc.alloc_size) +
                            sizeof(prog_desc.g_reloc_count) +
                            sizeof(prog_desc.l_reloc_count) +
                            sizeof(prog_desc.datasec_count) +
                            sizeof(prog_desc.code_count) +
                            (prog_desc.patch_table_count * 4) +
                            (prog_desc.datasec_count * 6);
    
    if (prog_desc.patch_table_count > 0 || prog_desc.datasec_count > 0) {
      if ((prog_desc.patch_table_count * 4) > (prog_desc.datasec_count * 6)) {
        tablesMemory = malloc(prog_desc.patch_table_count * 4);
      } else {
        tablesMemory = malloc(prog_desc.datasec_count * 6);
      }
    } else {
      tablesMemory = NULL;
    }
  }

  // Prepares the patch table before patching addresses in the binary code
  void loader_patch_table()
  {
    uint16_t i, tempUInt16 = 0;
    
    // Find out the total space global variables need, and malloc
    /*
    for (i = 0; i < (prog_desc.alloc_count * 4); i+=4) {
      tempUInt16 += *((uint16_t *)&tablesMemory[i]);
      *((uint16_t *)&tablesMemory[i]) = tempUInt16 - *((uint16_t *)&tablesMemory[i]);
    }
    */
    if (prog_desc.alloc_size > 0) {
      gVarMemory = malloc(prog_desc.alloc_size);
      memset(gVarMemory, 0, prog_desc.alloc_size);
    } else {
      gVarMemory = NULL;
    }
    
    // Some "real" addresses need offsets added. For example, local relocation table entries need
    // the starting code address
    for (i = 0; i < (prog_desc.patch_table_count * 4); i+=4) {
      if (i < (prog_desc.alloc_count * 4)) {
        tempUInt16 = (uint16_t)gVarMemory;   // Allocation table needs memory's offset
      } else if (i < ((prog_desc.alloc_count + prog_desc.g_reloc_count) * 4)) {
        tempUInt16 = 0;   // Global relocation table doesn't need anything
      } else {
        tempUInt16 = (uint16_t)code;   // Local relocation table needs code's offset
      }
      *((uint16_t *)&(tablesMemory[i])) = *((uint16_t *)&(tablesMemory[i])) + tempUInt16;   // Writes the real address
    }
    
    // Converts function IDs in global relocation table to real addresses
    for (i = (prog_desc.alloc_count * 4); i < ((prog_desc.alloc_count + prog_desc.g_reloc_count) * 4); i+=4) {
      tempUInt16 = *((uint16_t *)&tablesMemory[i]);   // Gets function ID
      tempUInt16 = (uint16_t)fun[tempUInt16].addr;   // Gets the real address of the function ID
      *((uint16_t *)&tablesMemory[i]) = tempUInt16;   // Writes the real address
    }
  }
  
  void loader_addr_1()
  {
    uint16_t i, laddr = 0, raddr = 0;
    
    // Resets before start
    nextTask_chain = 0x0;
    nextAddr = 0;
    
    // Gets the next task by searching for the lowest next patching address
    raddr = 0xFFFF;   // Temp variable to store the minimum patching address so far
    laddr = 0;   // Temp variable to store the current patching address
    for (i = 0; i < (prog_desc.patch_table_count * 4); i+=4) {
      laddr = *((uint16_t *)&tablesMemory[i + 2]);
      
      if (((uint16_t)nextTask_chain == 0x0 && laddr != 0xFFFF) || 
           raddr > laddr) {
        nextTask_chain = &(tablesMemory[i]);
        raddr = laddr;
      }
    }
    
    if (nextTask_chain != 0x0) {
      // Gets the next patching address in the chain from the flash
      raddr = *((uint16_t *)&nextTask_chain[2]);
      call ImageRead.read[readSource](readSourceOffset + prog_desc.code_offset + raddr, 
                                      &nextAddr, 
                                      2);
    } else {
      // Copies the rest of the binary code
      call ImageRead.read[readSource](readSourceOffset + prog_desc.code_offset + codePtr, 
                                      &(code[codePtr]), 
                                      prog_desc.code_count - codePtr);
      prog_desc.loading_stage++;
    }
  }
  
  // Patches the part of binary code that needs "real" addresses
  void loader_addr_2()
  {
    uint16_t laddr;
    
    laddr = *((uint16_t *)&nextTask_chain[2]);   // Gets the current patching address
    
    // Updates the chain with the next patching address
    if (nextAddr == 0x0000) {
      nextAddr = 0xFFFF;   // End of chain, marks it with a big number
    }
    *((uint16_t *)&nextTask_chain[2]) = nextAddr;
    
    // Patches address in the binary code
    *((uint16_t *)&code[laddr]) = *((uint16_t *)&nextTask_chain[0]);
    
    // Copies the binary code between the last patching address and the current patching address
    call ImageRead.read[readSource](readSourceOffset + prog_desc.code_offset + codePtr, 
                                    &(code[codePtr]), 
                                    laddr - codePtr);
    codePtr = laddr + 2;   // Notes up to what location in the binary code we have copied
  }
  
  void loader_datasec()
  {
    uint16_t i, j;
    
    for (i = 0; i < (prog_desc.datasec_count * 6); i+=6) {
      uint16_t destAddr = *((uint16_t *)&(tablesMemory[i])) + (uint16_t)gVarMemory;   // Writes the real address
      uint16_t srcAddr = *((uint16_t *)&(tablesMemory[i + 2])) + (uint16_t)code;   // Writes the real address
      uint16_t size = *((uint16_t *)&(tablesMemory[i + 4]));
      
      for (j = 0; j < size; j++) {
        ((uint8_t *)((void *)(destAddr + j)))[0] = ((uint8_t *)((void *)(srcAddr + j)))[0];
        //*((uint8_t *)&code[destAddr + j]) = *((uint8_t *)&code[srcAddr + j]);
      }
    }
  }
  
  void loadProgram()
  {
    error_t error = SUCCESS;
    switch (prog_desc.loading_stage) {
      case 0:
        // Loads meta data to memory array
        error = call ImageRead.read[readSource](readSourceOffset + 0, 
                                                &prog_desc, 
                                                7 * 2);
        if (error == SUCCESS) {
          prog_desc.loading_stage++;   // Moves to next loading phase
        } else {
          errorHandler();
        }
        break;
      
      case 1:
        loader_metaData();   // Gets meta data
        code = (void *) call PMManager.request(prog_desc.code_count);   // Gets the location of where the code will be copied to
        
        if ((uint16_t)code != 0xFFFF) {
          // Loads patch table to memory array
          error = call ImageRead.read[readSource](readSourceOffset + 7 * 2, 
                                                  tablesMemory, 
                                                  prog_desc.patch_table_count * 4);
          if (error == SUCCESS) {
            prog_desc.loading_stage++;   // Moves to next loading phase
          } else {
            errorHandler();
          }
        } else {
          errorHandler();
        }
        
        break;
      
      case 2:
        loader_patch_table();
        
        eeprom_w();   // Gets write-access to internal flash
        prog_desc.loading_stage++;   // Moves to next loading phase
      
      case 3:
        loader_addr_1();
        break;
      
      case 4:
        eeprom_r();   // Locks the internal flash back
        
        error = call ImageRead.read[readSource](readSourceOffset + 7 * 2 + prog_desc.patch_table_count * 4, 
                                                tablesMemory, 
                                                prog_desc.datasec_count * 6);
        if (error == SUCCESS) {
          prog_desc.loading_stage++;   // Moves to next loading phase
        } else {
          errorHandler();
        }
        
        break;
      case 5:
        loader_datasec();
        prog_desc.loading_stage++;
        
      case 6:
        post start_prog();
        break;
    }
  }
  
  command error_t Init.init()
  {
    int i;
    for (i = 0; i < TOSTHREAD_MAX_NUM_THREADS; i++) {
      threadCodeSizes[i] = 0;
      codeFirstAddrs[i] = 0;
    }
    initProgDesc();
    return SUCCESS;
  }
  
  task void taskLoadProgram()
  {
    loadProgram();
  }
  
  error_t start_load(uint8_t in_readSource, uint16_t in_readSourceOffset)
  {
    if (prog_desc.loading_stage == 0) {
      uint16_t i;
      call Leds.set(7);
      for (i = 0; i < 2000; i++) { }
      call Leds.set(0);
      
      readSource = in_readSource;
      readSourceOffset = in_readSourceOffset;
      post taskLoadProgram();   // Start Loading
      
      return SUCCESS;
    }
    
    return EBUSY;
  }
  
  command error_t DynamicLoader.loadFromFlash(uint8_t volumeId) { return start_load(volumeId, 0); }
  
  command error_t DynamicLoader.loadFromMemory(void *addr) { return start_load(READSOURCE_MEMORY, (uint16_t)addr); }
  
  event void ImageRead.readDone[uint8_t id](storage_addr_t addr, void* buf, storage_len_t len, error_t error)
  {
    if (error == SUCCESS) {
      if (buf == &nextAddr) {
        loader_addr_2();
      } else {
        post taskLoadProgram();
      }
    } else {
      errorHandler();
    }
  }

#ifndef DISABLE_LOADER_USERBUTTON
  event void UserButton.fired()
  {
     call DynamicLoader.loadFromFlash(VOLUME_MICROEXEIMAGE);
  }
#endif
  
  event void ImageRead.computeCrcDone[uint8_t id](storage_addr_t addr, storage_len_t len, uint16_t crc, error_t error) {}
  
  default command error_t ImageRead.read[uint8_t id](storage_addr_t addr, void *buf, storage_len_t len) { return FAIL; }
  default event void DynamicLoader.loadFromFlashDone(uint8_t volumeId, tosthread_t id, error_t error) {}
  default event void DynamicLoader.loadFromMemoryDone(void *addr, tosthread_t id, error_t error) {}
}
