/*
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
 * @author  Steve Ayer
 * @date    April, 2009
 * ported to tos-2.x
 * @date January, 2010
 */

#include "FatFs.h"

interface FatFs { 
  /* non-zero return codes indicate an error; the codes for these are in an enum in FatFs.h */

  command void asc_fattime(char * timestring);
  /*
   * do this before performing file ops!
   * pointer to FATFS struct provides required bookkeeping space for the fs
   */
  command error_t mount(FATFS * fs);

  command error_t unmount();

  /*
   * take the card down, "unmount" the fs
   */
  command void disable();

  /*
   * mode flags:
   * FA_READ	Specifies read access to the object. Data can be read from the file.
   *            Combine with FA_WRITE for read-write access.
   * FA_WRITE	Specifies write access to the object. Data can be written to the file.
                Combine with FA_READ for read-write access.
   * FA_OPEN_EXISTING	Opens the file. The function fails if the file is not existing. (Default)
   * FA_OPEN_ALWAYS	Opens the file, if it is existing. If not, the function creates the new file.
   * FA_CREATE_NEW	Creates a new file. The function fails if the file is already existing.
   * FA_CREATE_ALWAYS	Creates a new file. If the file is existing, it is truncated and overwritten.
   *
   */
  command error_t fopen(FIL * fp, const char * filename, BYTE mode);
  
  command error_t fclose(FIL * fp);
  
  command error_t fread(FIL * fp, 
			 void * buffer,
			 uint bytesToRead,
			 uint * bytesRead);

  command error_t fwrite(FIL * fp,
			  const void * buffer,
			  uint bytesToWrite,
			  uint * bytesWritten);

  // no ftell, but fp has fptr once file is open
  command error_t fseek(FIL * fp, int32_t offset);
  
  // truncate this file at the current location of the pointer
  command error_t ftruncate(FIL * fp);
  
  /* 
   * flush the file cache to physical media;  good for avoiding data loss due
   * to potential platform disruption (battery, app failure, media removal),
   * but should be used sparingly to avoid excess flash r/w cycles; fp struct has 
   * a 512-byte buffer.  
   */
  command error_t fsync(FIL * fp);

  command error_t mkdir(const char * dirname);

  command error_t chdir(const char * dirname);

  // feed it an empty DIR struct, used before doing readdir calls
  command error_t opendir(DIR * dp, const char * dirname);
  
  /*
   * reads dir entries in sequence until fi->fname is "" (fname[0] == NULL)
   *
   * since long filenames are used here, a buffer of sufficient size 
   * (_MAX_LFN + 1, unless using some asian code pages.  see FatFs.h)
   * must be attached to fi->lfname, with its size in fi->lfsize
   * 
   */
  command error_t readdir(DIR * dp, FILINFO * fi);
  
  /*
   * path is to root; fatfs struct is statically declared in driver
   */
  command error_t getfree(const char * path, uint32_t * clusters, FATFS ** fs);

  command error_t stat(const char * filename, FILINFO * fi);

  command error_t unlink(const char * filename);

  /*
   * this one's a bit weird
   * these are the flags for "value":
   * AM_RDO	Read only 	  (0x01)
   * AM_ARC     Archive           (0x20)
   * AM_SYS     System            (0x04)
   * AM_HID     Hidden            (0x02)
   * 
   * mask is for exposing attributes to effect of value flag; i.e., 
   * if the value bit is zero for a particular attribute and the mask 
   * has a 1 in that position (e.g. value is AM_HID|AM_RDO and mask is 
   * AM_HID|AM_SYS|AM_RDO, then AM_SYS will be turned off) that attribute 
   * will be disabled.
   */
  command error_t chmod(const char * filename, BYTE value, BYTE mask);

  /*
   * a good time to introduce this:
   * in timedate, the fields break out thus:
   * for fdate, 
   *    bit15:9
   *     Year origin from 1980 (0..127)
   *    bit8:5
   *     Month (1..12)
   *    bit4:0
   *     Day (1..31)
   *
   * for ftime,
   *    bit15:11
   *     Hour (0..23)
   *    bit10:5
   *     Minute (0..59)
   *    bit4:0
   *     Second / 2 (0..29)
   */
  command error_t f_utime(const char * filename, FILINFO * timedate);

  command error_t rename(const char * oldname, const char * newname);
  
  /*
   * size in sectors; 512 bytes/sector is fixed
   * a zero allocates the whole drive/card
   */
  command error_t mkfs(WORD allocSize);

  command const char * ff_strerror(error_t errnum);

  /*
   * these bubble the sd-driver-level events that the app has, 
   * or has lost, access to the card
   */
  async event void mediaUnavailable();
  async event void mediaAvailable();
}
