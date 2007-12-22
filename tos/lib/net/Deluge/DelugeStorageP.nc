/* Copyright (c) 2007 Johns Hopkins University.
*  All rights reserved.
*
*  Permission to use, copy, modify, and distribute this software and its
*  documentation for any purpose, without fee, and without written
*  agreement is hereby granted, provided that the above copyright
*  notice, the (updated) modification history and the author appear in
*  all copies of this source code.
*
*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS `AS IS'
*  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
*  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
*  ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS
*  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
*  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE, DATA,
*  OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
*  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
*  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
*  THE POSSIBILITY OF SUCH DAMAGE.
*/

/**
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 * @author Razvan Musaloiu-E. <razvanm@cs.jhu.edu>
 */

#include "Deluge.h"
#include "DelugePageTransfer.h"

module DelugeStorageP
{
  uses {
    interface BlockRead as SubBlockRead[uint8_t img_num];
    interface BlockWrite as SubBlockWrite[uint8_t img_num];
    interface Boot;
    interface Leds;
#if defined(PLATFORM_TELOSB)
    interface StorageMap[uint8_t img_num];
#elif defined(PLATFORM_MICAZ)
    interface At45dbVolume[volume_id_t img_num];
#endif
  }
  provides {
    interface BlockRead[uint8_t img_num];
    interface BlockWrite[uint8_t img_num];
    interface DelugeStorage[uint8_t img_num];
    interface DelugeMetadata;
    
    interface Notify<uint8_t> as ReadyNotify;
  }
}

implementation
{
  enum {
    S_READ_META,
    S_READ_CRC,
    S_CRC,
    S_READY,
  };

  uint8_t state;
  uint8_t current_image;
  uint8_t current_page;
  uint16_t current_crc;
  DelugeImgDesc imgDesc[DELUGE_NUM_VOLUMES];

  void nextImage()
  {
    if (current_image < DELUGE_NUM_VOLUMES) {
      state = S_READ_META;
      call SubBlockRead.read[current_image](0, &(imgDesc[current_image]), sizeof(DelugeImgDesc));
    } else {
      signal ReadyNotify.notify(SUCCESS);
      state = S_READY;
    }
  }  

  uint32_t calcCrcAddr()
  {
    return DELUGE_METADATA_SIZE + current_page * sizeof(uint16_t);
  }

  uint32_t calcPageAddr()
  {
    return DELUGE_METADATA_SIZE + current_page * DELUGE_BYTES_PER_PAGE;
  }

  event void Boot.booted()
  {
    uint32_t i;
    for (i = 0; i < DELUGE_NUM_VOLUMES; i++) {
      imgDesc[i].uid = DELUGE_INVALID_UID;
      imgDesc[i].vNum = 0;
      imgDesc[i].imgNum = 0;
      imgDesc[i].numPgs = 0;
      imgDesc[i].crc = 0;
      imgDesc[i].numPgsComplete = 0;
      imgDesc[i].reserved = 0;
      imgDesc[i].size = 0;
    }
    
    // We are going to iterate over all the images and verify their
    // integrity. For each image we first read the metadata to find
    // the number of pages and then iterate over all of them, compute
    // the CRC and check it against the corresponding value from the CRCs
    // block.
    state = S_READ_META;
    current_image = 0;
    nextImage();
  }

  command DelugeImgDesc* DelugeMetadata.getImgDesc(imgnum_t imgNum)
  {
    return &(imgDesc[imgNum]);
  }

  // SubBlockRead commands
  command error_t BlockRead.read[uint8_t img_num](storage_addr_t addr, void* buf, storage_len_t len)
  {
    return call SubBlockRead.read[img_num](addr, buf, len);
  }

  command error_t BlockRead.computeCrc[uint8_t img_num](storage_addr_t addr, storage_len_t len, uint16_t crc)
  {
    return call SubBlockRead.computeCrc[img_num](addr, len, crc);
  }

  command storage_len_t BlockRead.getSize[uint8_t img_num]()
  {
    return call SubBlockRead.getSize[img_num]();
  }

  // BlockRead events
  event void SubBlockRead.readDone[uint8_t img_num](storage_addr_t addr, void* buf, storage_len_t len, error_t error)
  {
    switch (state) {
    case S_READY:
      signal BlockRead.readDone[img_num](addr, buf, len, error);
      break;
    case S_READ_META:
      if (error == SUCCESS) {
	if (imgDesc[current_image].uid != DELUGE_INVALID_UID) {
	  current_page = 0;
	  state = S_READ_CRC;
	  call SubBlockRead.read[current_image](calcCrcAddr(), &current_crc, sizeof(current_crc));
	} else {
	  current_image++;
	  nextImage();
	}
      }      
      break;
    case S_READ_CRC:
      state = S_CRC;
      if (current_page == 0) {
	call SubBlockRead.computeCrc[current_image](calcPageAddr() + DELUGE_CRC_BLOCK_SIZE, 
						    DELUGE_BYTES_PER_PAGE - DELUGE_CRC_BLOCK_SIZE, 0);
      } else {
	call SubBlockRead.computeCrc[current_image](calcPageAddr(), DELUGE_BYTES_PER_PAGE, 0);
      }
      break;
    }
  }

  event void SubBlockRead.computeCrcDone[uint8_t img_num](storage_addr_t addr, storage_len_t len, uint16_t crc, error_t error)
  {
    switch (state) {
    case S_READY:
      signal BlockRead.computeCrcDone[img_num](addr, len, crc, error);
      break;
    case S_CRC:
      if (crc != current_crc) {
	// invalidate the image by erasing it
	call SubBlockWrite.erase[current_image]();
      } else {
	current_page++;
	if (current_page < imgDesc[current_image].numPgs) {
	  state = S_READ_CRC;
	  call SubBlockRead.read[current_image](calcCrcAddr(), &current_crc, sizeof(current_crc));
	} else {
	  current_image++;
	  nextImage();
	}
      }
      break;
    }
  }

  // SubBlockWrite commands
  command error_t BlockWrite.write[uint8_t img_num](storage_addr_t addr, void* buf, storage_len_t len)
  {
    return call SubBlockWrite.write[img_num](addr, buf, len);
  }

  command error_t BlockWrite.erase[uint8_t img_num]()
  {
    return call SubBlockWrite.erase[img_num]();
  }

  command error_t BlockWrite.sync[uint8_t img_num]()
  {
    return call SubBlockWrite.sync[img_num]();
  }

  // BlockWrite events
  event void SubBlockWrite.writeDone[uint8_t img_num](storage_addr_t addr, void* buf, storage_len_t len, error_t error)
  {
    if (error == SUCCESS) {
      if (addr < sizeof(DelugeImgDesc)) {
        memcpy((char*)&(imgDesc[img_num]) + addr, buf, sizeof(DelugeImgDesc) - addr);
      }
    }
    
    signal BlockWrite.writeDone[img_num](addr, buf, len, error);
  }

  event void SubBlockWrite.eraseDone[uint8_t img_num](error_t error)
  {
    if (error == SUCCESS) {
      // Successful erase triggers resetting the cached image description
      imgDesc[img_num].uid = DELUGE_INVALID_UID;
      imgDesc[img_num].vNum = 0;
      imgDesc[img_num].imgNum = 0;
      imgDesc[img_num].numPgs = 0;
      imgDesc[img_num].crc = 0;
      imgDesc[img_num].numPgsComplete = 0;
      imgDesc[img_num].reserved = 0;
      imgDesc[img_num].size = 0;
    }

    switch (state) {
    case S_READY:
      signal BlockWrite.eraseDone[img_num](error);
      break;
    case S_CRC:
      current_image++;
      nextImage();
      break;
    }
  }

  event void SubBlockWrite.syncDone[uint8_t img_num](error_t error)
  {
    signal BlockWrite.syncDone[img_num](error);
  }

  command storage_addr_t DelugeStorage.getPhysicalAddress[uint8_t img_num](storage_addr_t addr)
  {
    storage_addr_t p_addr = 0xFFFFFFFF;
    
    #if defined(PLATFORM_TELOSB)
      p_addr = call StorageMap.getPhysicalAddress[img_num](addr);
    #elif defined(PLATFORM_MICAZ)
      at45page_t page = call At45dbVolume.remap[img_num]((addr >> AT45_PAGE_SIZE_LOG2));
      at45pageoffset_t offset = addr & ((1 << AT45_PAGE_SIZE_LOG2) - 1);
      p_addr = page;
      p_addr = p_addr << AT45_PAGE_SIZE_LOG2;
      p_addr += offset;
    #endif
    
    return p_addr;
  }

  default event void BlockRead.readDone[uint8_t img_num](storage_addr_t addr, void* buf, storage_len_t len, error_t error) {}
  default event void BlockRead.computeCrcDone[uint8_t img_num](storage_addr_t addr, storage_len_t len, uint16_t crc, error_t error) {}
  default event void BlockWrite.writeDone[uint8_t img_num](storage_addr_t addr, void* buf, storage_len_t len, error_t error) {}
  default event void BlockWrite.eraseDone[uint8_t img_num](error_t error) {}
  default event void BlockWrite.syncDone[uint8_t img_num](error_t error) {}
  
  default command error_t SubBlockWrite.write[uint8_t img_num](storage_addr_t addr, void* buf, storage_len_t len) { return FAIL; }
  default command error_t SubBlockWrite.erase[uint8_t img_num]() { return FAIL; }
  default command error_t SubBlockWrite.sync[uint8_t img_num]() { return FAIL; }
  default command error_t SubBlockRead.read[uint8_t img_num](storage_addr_t addr, void* buf, storage_len_t len) { return FAIL; }
  default command error_t SubBlockRead.computeCrc[uint8_t img_num](storage_addr_t addr, storage_len_t len, uint16_t crc) { return FAIL; }
  default command storage_len_t SubBlockRead.getSize[uint8_t img_num]() { return 0; }
  
  command error_t ReadyNotify.enable() { return SUCCESS; }
  command error_t ReadyNotify.disable() { return SUCCESS; }
  
#if defined(PLATFORM_TELOSB)
  default command storage_addr_t StorageMap.getPhysicalAddress[uint8_t img_num](storage_addr_t addr) { return 0xFFFFFFFF; }
#elif defined(PLATFORM_MICAZ)
  default command at45page_t At45dbVolume.remap[volume_id_t volid](at45page_t volumePage) { return 0xFFFF; };
#endif
}
