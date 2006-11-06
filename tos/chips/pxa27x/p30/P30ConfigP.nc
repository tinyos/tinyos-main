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
 * @author Kaisen Lin
 * @author Phil Buonadonna
 *
 */
#include <P30.h>
#include <StorageVolumes.h>

module P30ConfigP {
  provides interface ConfigStorage as Config[ storage_volume_t v ];
  provides interface Mount[ storage_volume_t v ];

  uses interface Flash;
  uses interface Leds;
}

implementation {
  /*
   * These are some macros for convenience. Essentially it is cutting
   * a 2MB chunk into a two pieces. The size of the two pieces is
   * hardcoded by C_PARTITION_sIZE. It must be a multiple of
   * P30_BLOCK_SIZE because that is the erasable size. The bigger you
   * make the C_PARTITION_SIZE, the longer commits will take because
   * it must erase all the blocks inside. On the other hand, a larger
   * C_PARTITION_SIZE will give you a larger address space. v is the
   * parameterized interface that is used in the context of these
   * macros.
   */
#define C_PARTITION_SIZE (P30_BLOCK_SIZE*1)
#define C_PARTITION_0 (P30_VMAP[v].base * FLASH_PARTITION_SIZE)
#define C_PARTITION_1 (P30_VMAP[v].base * FLASH_PARTITION_SIZE + C_PARTITION_SIZE)
  typedef uint32_t version_t;

  enum {
    /*
     * WARNING: AT45DB has a RAM buffer that allows writes to occur
     * without actually writing to flash. We simulate this because it
     * makes rewrites a lot simpler. However, this essentially takes
     * RAM overhead. However, Configstores are relatively small and
     * the Intel PXA has a lot of main memory, so we do it anyway.
     */
    BUFFER_SIZE = 2048, 
    INVALID_VERSION = 0xFFFFFFFF,
    NUM_VOLS = _V_NUMVOLS_, //uniqueCount( "pxa27xp30.Volume" ),
  };
  
  typedef enum {
    S_IDLE,
    S_MOUNT,
    S_READ,
    S_WRITE,
    S_COMMIT,
  } p30_config_state_t;
  norace p30_config_state_t m_state = S_IDLE;

  /*
   * Each instantiation of a Configstore must keep certain state. This
   * includes the current version of the page and the active address
   * within that page since we are splitting it into two pieces. Each
   * Configstore must also have its own RAM buffer for concurrent
   * operations.
   */ 
  uint32_t currentVersion[NUM_VOLS];
  uint32_t activeBaseAddr[NUM_VOLS];
  uint8_t workBuf[BUFFER_SIZE*NUM_VOLS];

  storage_volume_t clientId = 0xff;
  storage_addr_t clientAddr;
  void* clientBuf;
  storage_len_t clientLen;
  error_t clientResult;

  task void signalDoneTask() {
    switch(m_state) {
    case S_MOUNT:
      m_state = S_IDLE;
      signal Mount.mountDone[clientId](clientResult);
      break;
    case S_WRITE:
      m_state = S_IDLE;
      signal Config.writeDone[clientId](clientAddr, clientBuf, clientLen, clientResult);
      break;
    case S_COMMIT:
      m_state = S_IDLE;
      signal Config.commitDone[clientId](SUCCESS);
      break;
    case S_READ:
      m_state = S_IDLE;
      signal Config.readDone[clientId](clientAddr, clientBuf, clientLen, clientResult);
      break;
    default:
      break;
    }
  }

  /* 
   * Erase a config partition. It may be more than one P30 block size,
   * so erase multiple times.
   */
  void eraseConfigPartition(uint32_t base) {
    uint32_t blocks;
    
    for(blocks = C_PARTITION_SIZE / P30_BLOCK_SIZE;
	blocks > 0;
	blocks--) {
      call Flash.erase(base);
      base += P30_BLOCK_SIZE;
    }
  }

  /*
   * Read the data directly from the RAM buffer into the client
   * buffer... Might be read from Flash depending on semantics
   */
  command error_t Config.read[storage_volume_t v](storage_addr_t addr,
							  void* buf,
							  storage_len_t len) {
    uint32_t i;

    clientId = v;
    clientAddr = addr;
    clientBuf = buf;
    clientLen = len;

    m_state = S_READ;

    /*
    for(i = addr; i < addr + len; i++) {
      ((uint8_t*)buf)[i-addr] = workBuf[(v*BUFFER_SIZE)+i];
    }
    */
    call Flash.read(activeBaseAddr[v] + addr,
		    (uint8_t*) buf,
		    len);
    
    post signalDoneTask();
    
    return SUCCESS;
  }

  /*
   * Writes the client data into the given address in the RAM
   * buffer. Data is not actually written to flash until the user
   * commits.
   */
  command error_t Config.write[storage_volume_t v](storage_addr_t addr,
							   void* buf,
							   storage_len_t len) {
    uint32_t i;

    clientId = v;
    clientAddr = addr;
    clientBuf = buf;
    clientLen = len;

    // error check
    if(addr + len > BUFFER_SIZE)
      return FAIL; // out of my artificial bounds

    m_state = S_WRITE;

    for(i = addr; i < addr + len; i++)
      workBuf[(v*BUFFER_SIZE)+i] = ((uint8_t*)buf)[i-addr];

    clientResult = SUCCESS;
    post signalDoneTask();
    return SUCCESS;
  }

  /*
   * Determine which partition to write to based on the current one
   * that is active. Also update the version number. Version numbers
   * are 0, 1, 2, or 3 and wraps around. Write the RAM buffer out
   * first BEFORE writing the the new version number. After the
   * version number is written, the active config is now atomically
   * switched. Then update any other in memory metadata.
   */
  command error_t Config.commit[storage_volume_t v]() {
    uint32_t destBaseAddr;

    if(activeBaseAddr[v] == C_PARTITION_0)
      destBaseAddr = C_PARTITION_1;
    else
      destBaseAddr = C_PARTITION_0;

    m_state = S_COMMIT;

    clientId = v;
    clientResult = SUCCESS;

    currentVersion[v] = (currentVersion[v] + 1) % 4;

    // erase target flash area before writing to it
    eraseConfigPartition(destBaseAddr);

    // write RAM buffer out
    call Flash.write(destBaseAddr,
		     (uint8_t*) &workBuf[v*BUFFER_SIZE],
		     BUFFER_SIZE);

    call Flash.write(destBaseAddr + C_PARTITION_SIZE - sizeof(version_t),
		     (uint8_t*) &currentVersion[v],
		     sizeof(version_t));

    activeBaseAddr[v] = destBaseAddr;

    post signalDoneTask();
    return SUCCESS;
  }

  /*
   * The only metadata that needs to be saved is a version
   * number. Thus you get the whole partition minus the version number
   * in terms of space.
   */
  command storage_len_t Config.getSize[storage_volume_t v]() {
    return C_PARTITION_SIZE - sizeof(version_t);
  }

  command bool Config.valid[storage_volume_t v]() {
    return TRUE;
  }

  /*
   * When a Configstore is mounted, it must do some initial
   * book-keeping work. It first reads from the two pieces two
   * determine, which one is the actual active one. Afterwards, we
   * read from flash into the RAM buffer or else subsequent reads will
   * not work.
   */
  command error_t Mount.mount[storage_volume_t v]() {
    version_t v0;
    version_t v1;

    m_state = S_MOUNT;
    clientResult = SUCCESS;
    clientId = v;

    currentVersion[v] = INVALID_VERSION;

    // read version #s from both sectors and determine new one
    // pick among 0 1 2 3 FFFF
    call Flash.read(C_PARTITION_0 + C_PARTITION_SIZE - sizeof(version_t),
		    (uint8_t*)&v0, sizeof(version_t));
    call Flash.read(C_PARTITION_1 + C_PARTITION_SIZE - sizeof(version_t),
		    (uint8_t*)&v1, sizeof(version_t));

    // this logic in this could probably be simplified
    if(v0 == INVALID_VERSION && v1 == INVALID_VERSION) {
      // clean partition
      activeBaseAddr[v] = C_PARTITION_0;
      currentVersion[v] = 0;
    }
    else if(v1 == INVALID_VERSION) {
      // use v0
      activeBaseAddr[v] = C_PARTITION_0;
      currentVersion[v] = v0;
    }
    else if(v0 == INVALID_VERSION) {
      // use v1
      activeBaseAddr[v] = C_PARTITION_1;
      currentVersion[v] = v1;
    }
    else if((v0 + 1) % 4 == v1) {
      // use v1
      activeBaseAddr[v] = C_PARTITION_1;
      currentVersion[v] = v1;
    }
    else if((v1 + 1) % 4 == v0) {
      // use v0
      activeBaseAddr[v] = C_PARTITION_0;
      currentVersion[v] = v0;
    }
    else {
      // corrupted? erase both, might want to improve this later
      eraseConfigPartition(C_PARTITION_0);
      eraseConfigPartition(C_PARTITION_1);
      currentVersion[v] = 0;
    }

    // read into RAM buffer
    call Flash.read(activeBaseAddr[v], (uint8_t*)&workBuf[v*BUFFER_SIZE], BUFFER_SIZE);

    post signalDoneTask();
    return SUCCESS;
  }

  default event void Config.readDone[storage_volume_t v](storage_addr_t addr, void* buf, storage_len_t len, error_t error) {}
  default event void Config.writeDone[storage_volume_t v](storage_addr_t addr, void* buf, storage_len_t len, error_t error) {}
  default event void Config.commitDone[storage_volume_t v](error_t error) {}
  default event void Mount.mountDone[storage_volume_t v](error_t error) {}
}

