/*----------------------------------------------------------------------------/
  / FatFs module is an open source project to implement FAT file system to small
  / embedded systems. It is opened for education, research and development under
  / license policy of following trems.
  /
  /  Copyright (C) 2009, ChaN, all right reserved.
  /
  / * The FatFs module is a free software and there is no warranty.
  / * You can use, modify and/or redistribute it for personal, non-profit or
  /   commercial use without any restriction under your responsibility.
  / * Redistributions of source code must retain the above copyright notice.
  /
  /----------------------------------------------------------------------------*/
/*
 * Most of this code:
 *
 * Copyright (c) 2009, Shimmer Research, Ltd.
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:

 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * Neither the name of Shimmer Research, Ltd. nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.

 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * tinyos instantiation of ChaN's diskio stubs (thank you!):
 * function declarations are kept from ChaN's code to make updating easier;
 * contents of these point to abstract calls -- as "diskio" -- 
 * to real physical io; for now, the control will point to SD.
 *
 * @author Steve Ayer
 * @date   April, 2009
 * ported from tos-1.x 
 * @date   January, 2010
 */

#include "diskio.h"

static BOOL disk_available, disk_initialized;

DSTATUS disk_initialize (BYTE drv)	// we only have one
{
  if(!disk_initialized){
    atomic disk_available = TRUE;

    call diskIOStdControl.start();
    
    atomic disk_initialized = TRUE;
  }
  return 0;
}

void disable_disk()
{
  atomic disk_available = FALSE;
  
  disk_initialized = FALSE;
  
  call diskIOStdControl.stop();
}

void dock_disk()
{
  atomic disk_available = FALSE;
  
  call diskIOStdControl.start();
}

void disable_dock()
{
  call diskIO.disableDock();
}

void enable_dock()
{
  call diskIO.enableDock();
}

DSTATUS disk_status (BYTE drv)        // just one
{
  atomic {
    if(!disk_available)
      return STA_NOINIT;
  }
  
  return FR_OK;

}

DRESULT disk_read (BYTE drv,		
		   BYTE * buff,		/* Data buffer to store read data */
		   DWORD sector,	/* Sector address (LBA) */
		   BYTE count)		/* Number of sectors to read (1..255) */
{
  int result = FR_OK;
  register int i;

  if(disk_available){
    for(i = 0; i < count; i++)
      if((result = call diskIO.readBlock(sector++, (uint8_t *)(buff + i * 512))))   // success is (still) 0
	break;
  }
  else
    result = FR_NOT_READY;

  return result;
}

#if _READONLY == 0
DRESULT disk_write (BYTE drv,		
		    const BYTE *buff,	/* Data to be written */
		    DWORD sector,		/* Sector address (LBA) */
		    BYTE count)			/* Number of sectors to write (1..255) */
{
  int result = FR_OK;
  register int i;

  if(disk_available){
    for(i = 0; i < count; i++)
      if((result = call diskIO.writeBlock(sector++, (uint8_t *)(buff + i * 512))))   // success is (still) 0
	break;
  }
  else
    return FR_NOT_READY;

  return result;
}
#endif /* _READONLY */

DRESULT disk_ioctl (BYTE drv,
		    BYTE ctrl,		/* Control code */
		    void * answer)		/* Buffer to send/receive control data */
{
  int result;
  uint32_t capacity;   // bytes
  /* 
   * calls we have to deal with (ctrl param) as of ff v0.07a:
   *
   * CTRL_SYNC make sure no accesses are pending
   * GET_SECTOR_SIZE we're only supporting sd so far
   * GET_BLOCK_SIZE  right, as above
   * GET_SECTOR_COUNT sd driver has a read-success hack for this, should work
   */
  switch(ctrl){
  case CTRL_SYNC:   // make sure we have availability
    atomic{
      if(disk_available)
	result = FR_OK;
      else
	result = FR_NOT_READY;
    }
    break;
  case GET_SECTOR_SIZE:
  case GET_BLOCK_SIZE:
    *(WORD *)answer = 512;
    result = RES_OK;
    break;
  case GET_SECTOR_COUNT:
    capacity = call diskIO.readCardSize();
    *(DWORD *)answer = capacity / 512;
    result = FR_OK;
    break;
  default:
    *(WORD *)answer = 0;
    result = FR_INVALID_NAME;
    break;
  }
  return result;
}

async event void diskIO.available(){
  signal FatFs.mediaAvailable();
  
  atomic disk_available = TRUE;
}

async event void diskIO.unavailable(){
  signal FatFs.mediaUnavailable();
  
  atomic disk_available = FALSE;
}

