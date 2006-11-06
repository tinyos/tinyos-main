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

module P30LogP {
  provides interface LogRead as Read[ storage_volume_t block ];
  provides interface LogWrite as Write[ storage_volume_t block ];

  uses interface Leds;
  uses interface Flash;
  uses interface Get<bool> as Circular[ storage_volume_t block ];
}

implementation {

#define SEEK_BEGINNING (0x0)
#define SEEK_EOL (0xFFFFFFFF)
#define L_BASE_BLOCK(_x) (P30_VMAP[_x].base * FLASH_PARTITION_SIZE)
#define L_PARTITIONS(_x) ((P30_VMAP[_x].size * FLASH_PARTITION_SIZE) / P30_BLOCK_SIZE)
#define L_FULL_RECORD_SIZE (sizeof(record_data_t) + sizeof(record_meta_t))
#define L_RECORD_DATA_SIZE 256
#define L_MAX_RECORDS_PER_BLOCK (P30_BLOCK_SIZE / L_FULL_RECORD_SIZE) // page meta counts as one record
  // _a = blockId (from parameterized interface), _b = page, _c = record
#define L_RAW_OFFSET(_a,_b,_c) (L_BASE_BLOCK(_a) + (_b * P30_BLOCK_SIZE) + (_c * L_FULL_RECORD_SIZE))

  enum {
    INVALID_VERSION = 0xFFFFFFFF,
    NUM_VOLS = _V_NUMVOLS_, //uniqueCount("pxa27xp30.Volume"),
  };

  enum {
    PAGE_START = 0x0000,
    PAGE_USED = 0xFFF0,
    PAGE_AVAILABLE = 0xFFFF,
  };
  typedef struct page_meta_t {
    uint16_t header;
  } page_meta_t;

  enum {
    RECORD_VALID = 0x0000,
    RECORD_INVALID = 0xFFF0,
    RECORD_EMPTY = 0xFFFF,
  };
  typedef struct record_meta_t {
    uint16_t status;
    uint16_t length;
  } record_meta_t;
  typedef struct record_data_t {
    uint8_t data[L_RECORD_DATA_SIZE];
  } record_data_t;

  typedef enum {
    S_IDLE,
    S_READ,
    S_APPEND,
    S_SYNC,
    S_ERASE,
    S_SEEK,
  } p30_log_state_t;
  norace p30_log_state_t m_state = S_IDLE;
  storage_volume_t clientId = 0xff;
  void* clientBuf;
  storage_len_t clientLen;
  error_t clientResult;

  uint32_t firstBlock[NUM_VOLS]; // 0-15 for 2 MB
  uint32_t lastBlock[NUM_VOLS]; // 0-15 for 2 MB
  uint32_t nextFreeRecord[NUM_VOLS]; // 0-X depending on data size
  storage_cookie_t readCookieOffset[NUM_VOLS]; // this is a raw offset
  bool gbOverwriteOccured = FALSE;

  /* This shuffles all the blocks when we run out of space. We have to
   * do it in a special order so crash recovery is possible. We also
   * have to write special bytes so we can rewrite to areas without
   * doing a complete erase.
   */
  void shuffleBlocks(storage_volume_t block) {
    page_meta_t pageMeta;
    uint32_t pageCounter;
    // 1. set the last block to USED, if it's already USED or START, then no effect
    pageMeta.header = PAGE_USED;
    call Flash.write(L_RAW_OFFSET(block, lastBlock[block], 0),
		     (uint8_t*) &pageMeta,
		     sizeof(page_meta_t));
    // 2. if lastBlock + 1 is free, then set it as last block and the first record is free
    pageCounter = (lastBlock[block] + 1) % L_PARTITIONS(block);
    call Flash.read(L_RAW_OFFSET(block, pageCounter, 0),
		    (uint8_t*) &pageMeta,
		    sizeof(page_meta_t));
    if(pageMeta.header == PAGE_AVAILABLE) {
      nextFreeRecord[block] = 1;
      lastBlock[block] = pageCounter;
    }
    else {
      call Flash.erase(L_RAW_OFFSET(block, firstBlock[block], 0));
      pageCounter = (firstBlock[block] + 1) % L_PARTITIONS(block);
      pageMeta.header = PAGE_START;
      call Flash.write(L_RAW_OFFSET(block, pageCounter, 0),
		       (uint8_t*) &pageMeta,
		       sizeof(page_meta_t));
      nextFreeRecord[block] = 1;
      lastBlock[block] = firstBlock[block];
      firstBlock[block] = pageCounter;
      gbOverwriteOccured = TRUE;
    }
  }

  /*
   * Converts a cookie to a page/record/offset tuple
   */
  void cookieToTuple(uint32_t cookie, storage_volume_t block,
		     uint32_t *page, uint32_t *record, uint32_t *offset) {

    uint32_t mypage;
    uint32_t myrecord;
    uint32_t myoffset;

    mypage = (cookie - L_BASE_BLOCK(block)) / P30_BLOCK_SIZE;
    cookie = (cookie - L_BASE_BLOCK(block)) % P30_BLOCK_SIZE;
    myrecord = cookie / L_FULL_RECORD_SIZE;
    myoffset = (cookie % L_FULL_RECORD_SIZE) - sizeof(record_meta_t);

    *page = mypage;
    *record = myrecord;
    *offset = myoffset;
  }

  /*
   * Ideally, Logstorage would require a mount too, but it doesn't so
   * it's a total hack. Before any operation, we have to check if a
   * mount occurred. Mount initializes the your logblock.
   */
  uint8_t mountBits[NUM_VOLS];
  void myMount(storage_volume_t block) {
    page_meta_t pageMeta;
    record_meta_t recordMeta;
    uint32_t pageCounter;
    uint32_t recordCounter;

    uint32_t freePages = 0;

    if(mountBits[block] != 0)
      return;

    // scan all 128k pages for page meta

    // annoying corner case of all free pages, write the first page as START
    for(pageCounter = 0; pageCounter < L_PARTITIONS(block); pageCounter++) {
      call Flash.read(L_RAW_OFFSET(block, pageCounter, 0),
		      (uint8_t*)&pageMeta,
		      sizeof(page_meta_t));
      if(pageMeta.header == PAGE_AVAILABLE)
	freePages++;
    }
    if(freePages == L_PARTITIONS(block)) {
      pageMeta.header = PAGE_START;
      call Flash.write(L_RAW_OFFSET(block, 0, 0), (uint8_t*) &pageMeta, sizeof(page_meta_t));
    }

    // if we find a START page, then we are done
    for(pageCounter = 0; pageCounter < L_PARTITIONS(block); pageCounter++) {
      call Flash.read(L_RAW_OFFSET(block, pageCounter, 0),
		      (uint8_t*)&pageMeta,
		      sizeof(page_meta_t));
      if(pageMeta.header == PAGE_START) {
	firstBlock[block] = pageCounter;
	break;
      }
    }
    // if we didn't find a START page, first page is right after AVAILABLE
    if(pageCounter == L_PARTITIONS(block)) {
      for(pageCounter = 0; pageCounter < L_PARTITIONS(block); pageCounter++) {
	call Flash.read(L_RAW_OFFSET(block, pageCounter, 0),
			(uint8_t*)&pageMeta,
			sizeof(page_meta_t));
	if(pageMeta.header == PAGE_AVAILABLE) {
	  pageCounter = (pageCounter + 1) % L_PARTITIONS(block);
	  firstBlock[block] = pageCounter;
	  // mark that block as a START block
	  pageMeta.header = PAGE_START;
	  call Flash.write(L_RAW_OFFSET(block, pageCounter, 0),
			   (uint8_t*) &pageMeta,
			   sizeof(page_meta_t));
	  break;
	}
      }
    }
    // now we scan for next free record location
    pageCounter = firstBlock[block];
    for(recordCounter = 1; recordCounter < L_MAX_RECORDS_PER_BLOCK; recordCounter++) {
      call Flash.read(L_RAW_OFFSET(block, pageCounter, recordCounter),
		      (uint8_t*) &recordMeta,
		      sizeof(record_meta_t));
      if(recordMeta.status == RECORD_EMPTY) {
	nextFreeRecord[block] = recordCounter;
	lastBlock[block] = pageCounter;
	break;
      }
    }
    // Didn't find a free record in the START block, search the first FREE block
    if(recordCounter == L_MAX_RECORDS_PER_BLOCK) {
      for(pageCounter = 0; pageCounter < L_PARTITIONS(block); pageCounter++) {
	call Flash.read(L_RAW_OFFSET(block, pageCounter, 0),
			(uint8_t*)&pageMeta,
			sizeof(page_meta_t));
	if(pageMeta.header == PAGE_AVAILABLE) {
	  for(recordCounter = 1; recordCounter < L_MAX_RECORDS_PER_BLOCK; recordCounter++) {
	    call Flash.read(L_RAW_OFFSET(block, pageCounter, recordCounter),
			    (uint8_t*) &recordMeta,
			    sizeof(record_meta_t));
	    if(recordMeta.status == RECORD_EMPTY) {
	      lastBlock[block] = pageCounter;
	      nextFreeRecord[block] = recordCounter;
	      goto mount_complete;
	    }
	  }
	}
      }
      // if here, you didn't find the last block, it must be right before the START block
      // special case the wrap around
      if(firstBlock[block] == 0)
	lastBlock[block] = L_PARTITIONS(block) - 1;
      else
	lastBlock[block] = firstBlock[block] - 1;
      // that last block must be full, so shuffle it
      shuffleBlocks(block);
    }

  mount_complete:
    readCookieOffset[block] = SEEK_BEGINNING;
    mountBits[block] = 1;
  }

  task void signalDoneTask() {
    switch(m_state) {
    case S_APPEND:
      m_state = S_IDLE;
      signal Write.appendDone[clientId](clientBuf, clientLen, gbOverwriteOccured, clientResult);
      gbOverwriteOccured = FALSE;
      break;
    case S_SYNC:
      m_state = S_IDLE;
      signal Write.syncDone[clientId](SUCCESS);
      break;
    case S_ERASE:
      m_state = S_IDLE;
      signal Write.eraseDone[clientId](clientResult);
      break;
   case S_READ:
      m_state = S_IDLE;
      signal Read.readDone[clientId](clientBuf, clientLen, clientResult);
      break;
   case S_SEEK:
      m_state = S_IDLE;
      signal Read.seekDone[clientId](SUCCESS);
      break;
    default:
      break;
    }
  }

  /*
   * Invariant should be that everytime after an append completes,
   * nextFreeRecord should point to a valid free record slot. Uses
   * nextFreeRecord to append.
   */
  command error_t Write.append[ storage_volume_t block ](void* buf, storage_len_t len) {
    record_meta_t recordMeta;

    myMount(block);
    
    // error check
    if(len > L_RECORD_DATA_SIZE)
      return EINVAL;

    // if non circular log, fail
    if((!call Circular.get[block]()) &&
       (lastBlock[block] == (L_PARTITIONS(block) - 1)) &&
       (nextFreeRecord[block] == (L_MAX_RECORDS_PER_BLOCK - 1)))
      return FAIL;

    m_state = S_APPEND;
    clientId = block;
    clientBuf = buf;
    clientLen = len;

    // if you try to log 0, just immediately succeed, this really shouldn't happen
    if(len == 0) {
      clientResult = SUCCESS;
      post signalDoneTask();
      return SUCCESS;
    }

    // if readCookie was on SEEK_EOL, adjust it back to here
    if(readCookieOffset[block] == SEEK_EOL)
      readCookieOffset[block] = L_RAW_OFFSET(block, lastBlock[block], nextFreeRecord[block]) + sizeof(record_meta_t);
      
    // use next free record, write the INVALID, write the data, write the VALID
    recordMeta.status = RECORD_INVALID;
    recordMeta.length = len;
    call Flash.write(L_RAW_OFFSET(block, lastBlock[block], nextFreeRecord[block]),
		     (uint8_t*) &recordMeta,
		     sizeof(record_meta_t));
    call Flash.write(L_RAW_OFFSET(block, lastBlock[block], nextFreeRecord[block]) +
		     sizeof(record_meta_t),
		     (uint8_t*) buf, len);
    recordMeta.status = RECORD_VALID;
    call Flash.write(L_RAW_OFFSET(block, lastBlock[block], nextFreeRecord[block]),
		     (uint8_t*) &recordMeta,
		     sizeof(record_meta_t));
    nextFreeRecord[block]++;
    // see if you need to adjust blocks or shuffle
    if(nextFreeRecord[block] == L_MAX_RECORDS_PER_BLOCK)
      shuffleBlocks(block);

    clientResult = SUCCESS;
    post signalDoneTask();
    
    return SUCCESS;
  }

  /*
   * We use nextFreeRecord to get the cookie
   */
  command storage_cookie_t Write.currentOffset[ storage_volume_t block ]() {
    myMount(block);

    return L_RAW_OFFSET(block, lastBlock[block], nextFreeRecord[block]) +
      sizeof(record_meta_t);
  }

  /*
   * First we erase all the log data blocks so that they can be
   * reused. Then we zero the cookies and then write them to our
   * partitions like the append operation. If we crash in the middle,
   * you may have to erase again. However, if an erase does fail, at
   * least all your data will still be there, so that you can try
   * again.
   */
  command error_t Write.erase[storage_volume_t block]() {
    uint32_t i;

    for(i = 0; i < L_PARTITIONS(block); i++) {
      call Flash.erase(L_BASE_BLOCK(block) + (i * P30_BLOCK_SIZE));
    }

    mountBits[block] = 0;
    myMount(block);

    // ... starting block implicitly written by mount

    m_state = S_ERASE;
    clientId = block;
    clientResult = SUCCESS;
    post signalDoneTask();

    return SUCCESS;
  }

  /*
   * Sync does nothing really because unlike the AT45DB, Intel P30
   * writes directly through.
   */
  command error_t Write.sync[storage_volume_t block]() {
    myMount(block);

    m_state = S_SYNC;
    
    clientId = block;
    clientResult = SUCCESS;
    
    post signalDoneTask();
    return SUCCESS;

  }

  /*
   * Sanity check the read cookie and adjust for any other special
   * cookies. Because you can seek to the byte, must it is saved in
   * flash as records, you have to do a lot of tricky seeking, but
   * it's done here. Also has to handle any pages that are spilled
   * over.
   */
  command error_t Read.read[ storage_volume_t block ](void* buf, storage_len_t len) {
    record_meta_t recordMeta;
    uint32_t recordCounter;
    uint32_t pageCounter;
    uint32_t offset;

    clientId = block;
    clientBuf = buf;
    clientResult = SUCCESS;

    myMount(block);

    m_state = S_READ;
    
    if(len == 0 || readCookieOffset[block] == SEEK_EOL) {
      clientResult = SUCCESS;
      clientLen = 0;
      post signalDoneTask();
      return SUCCESS;
    }
    
    // adjust SEEK_BEGINNING to a real offset
    if(readCookieOffset[block] == SEEK_BEGINNING) {
      readCookieOffset[block] = L_RAW_OFFSET(block, firstBlock[block], 1) +
	sizeof(record_meta_t);
    }
    
    // convert the cookie to something useful
    cookieToTuple(readCookieOffset[block], block, &pageCounter, &recordCounter, &offset);
    // sanity check readCookie
    call Flash.read(L_RAW_OFFSET(block, pageCounter, recordCounter),
		    (uint8_t*) &recordMeta,
		    sizeof(record_meta_t));
    if((recordMeta.status == RECORD_VALID) && (offset > len)) {
      readCookieOffset[block] = L_RAW_OFFSET(block, firstBlock[block], 0) + sizeof(record_meta_t);
      cookieToTuple(readCookieOffset[block], block, &pageCounter, &recordCounter, &offset);
    }

    clientLen = 0; // reset how much actually read and count up

    
    while(len != 0) {
      call Flash.read(L_RAW_OFFSET(block, pageCounter, recordCounter),
		      (uint8_t*) &recordMeta,
		      sizeof(record_meta_t));
      if(recordMeta.status == RECORD_INVALID) {
	goto advance_counter;
      }
      if(recordMeta.status == RECORD_EMPTY) {
	readCookieOffset[block] = SEEK_EOL;
	post signalDoneTask();
	return SUCCESS;
      }
      // read partial block and finish
      if(len < recordMeta.length + offset) {
	call Flash.read(L_RAW_OFFSET(block, pageCounter, recordCounter) +
			offset + sizeof(record_meta_t),
			buf,
			len);
	offset = len;
	buf = buf + len;
	len = 0;
      }
      else {
	call Flash.read(L_RAW_OFFSET(block, pageCounter, recordCounter) + 
			offset + sizeof(record_meta_t),
			buf,
			recordMeta.length - offset);
	clientLen = clientLen + recordMeta.length - offset;
	len -= recordMeta.length - offset;
	buf = buf + recordMeta.length - offset;
	offset = 0;
      
      advance_counter:
	recordCounter++;
	if((recordCounter >= L_MAX_RECORDS_PER_BLOCK) && (pageCounter == lastBlock[block])) {
	  readCookieOffset[block] = SEEK_EOL;
	  post signalDoneTask();
	  return SUCCESS;
	}
	// need to adjust page possibly if spills
	// also need to check if reached end of log (lastBlock[block] or RECORD_AVAILABLE)
	if(recordCounter >= L_MAX_RECORDS_PER_BLOCK) {
	  pageCounter = (pageCounter + 1) % L_PARTITIONS(block);
	  recordCounter = 1;
	}
      }
    }

    readCookieOffset[block] = L_RAW_OFFSET(block, pageCounter, recordCounter) +
      sizeof(record_meta_t) + offset;
    post signalDoneTask();
    return SUCCESS;
  }
    
  command storage_cookie_t Read.currentOffset[ storage_volume_t block ]() {
    myMount(block);
    return readCookieOffset[block];
  }

  /*
   * Just set the cookie. If you seek into an invalid area, just set
   * it at SEEK_BEGINNING.
   */
  command error_t Read.seek[ storage_volume_t block ](storage_cookie_t offset) {
    uint32_t page;
    uint32_t record;
    uint32_t recordOffset;
    record_meta_t recordMeta;
    myMount(block);

    clientId = block;
    clientResult = SUCCESS;

    m_state = S_SEEK;

    readCookieOffset[block] = offset;

    post signalDoneTask();      
    
    return SUCCESS;
  }

  /*
   * Go through all the pages, if it's a free page, count whatever is
   * available left. Add them all up.
   */
  command storage_len_t Read.getSize[ storage_volume_t block ]() {
    storage_len_t len = 0;
    uint32_t i;
    uint32_t j;
    page_meta_t pageMeta;
    record_meta_t recordMeta;
    
    myMount(block);
    
    for(i = 0; i < L_PARTITIONS(block); i++) {
      call Flash.read(L_RAW_OFFSET(block, i, j),
		      (uint8_t*) &pageMeta,
		      sizeof(page_meta_t));
      if(pageMeta.header != PAGE_AVAILABLE) {
	len = len + (sizeof(record_data_t) * L_MAX_RECORDS_PER_BLOCK);
	continue;
      }
      for(j = 1; j < L_MAX_RECORDS_PER_BLOCK; j++) {
	call Flash.read(L_RAW_OFFSET(block, i, j),
			(uint8_t*) &recordMeta,
			sizeof(record_meta_t));
	if(recordMeta.status == RECORD_EMPTY) {
	  len = len + ((L_MAX_RECORDS_PER_BLOCK - j) * sizeof(record_meta_t));
	  break;
	}
      }
    }
    
    return len;
  }

  default event void Read.readDone[ storage_volume_t block ](void* buf, storage_len_t len, error_t error) {}
  default event void Read.seekDone[ storage_volume_t block ](error_t error) {}
  default event void Write.appendDone[ storage_volume_t block ](void* buf, storage_len_t len, bool recordsLost, error_t error) {}

  default event void Write.eraseDone[ storage_volume_t block ](error_t error) {}
  default event void Write.syncDone[ storage_volume_t block ](error_t error) {}

  default command bool Circular.get[ uint8_t id ]() { return FALSE; }
}
