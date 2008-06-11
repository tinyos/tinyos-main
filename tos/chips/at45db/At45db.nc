// $Id: At45db.nc,v 1.6 2008-06-11 00:46:23 razvanm Exp $

/*
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

#include "At45db.h"

/**
 * HAL for Atmel's AT45DB family of serial dataflash chips. This provides
 * reasonably high-level operations on AT45DB pages, including automatic
 * buffer management. Writes are only guaranteed to happen after a flush,
 * flushAll, sync or syncAll.
 * <p>
 * When buffers are flushed to the flash (either explicitly or implicitly),
 * their contents are checked to ensure the write was succesful. If this
 * check fails, the flush is retried some number of times. If this fails
 * more than some number of times, all access to the flash is disabled
 * (all requests will report FAIL in their completion event).
 * <p>
 * This interface only supports one operation at a time - components offering
 * At45db should use the <code>Resource</code> interface for resource sharing.
 *
 * @author David Gay
 */

interface At45db {
  /**
   * Write some data to an AT45DB page. writeDone will be signaled.
   * @param page Flash page to write to. Must be less than AT45_MAX_PAGES.
   * @param offset Offset in page at which to start writing - must be between
   *   0 and AT45_PAGE_SIZE - 1 
   * @param data Data to write. The buffer is "returned" at writeDone time.
   * @param n Number of bytes to write (> 0). offset + n must be <= 
   *   AT45_PAGE_SIZE
   */
  command void write(at45page_t page, at45pageoffset_t offset,
		     void *PASS COUNT(n) data, at45pageoffset_t n);
  /**
   * Signal completion of a write operation. The buffer passed to write
   * is implictly returned.
   * @param error SUCCESS for a successful write, FAIL otherwise
   */
  event void writeDone(error_t error);

  /**
   * Copy one flash page to another. copyDone will be signaled. If page
   * from had been modified, it is first flushed to flash. Page
   * <code>to</code> will only actually be written when the buffer holding
   * it is flushed (see flush, flushAll, sync, syncAll).
   *
   * @param from Flash page to copy. Must be less than AT45_MAX_PAGES.
   * @param to Flash page to overwrite. Must be less than AT45_MAX_PAGES.
   */
  command void copyPage(at45page_t from, at45page_t to);
  /**
   * Signal completion of a copyPage operation. 
   * @param error SUCCESS if the copy was successful, FAIL otherwise
   */
  event void copyPageDone(error_t error);

  /**
   * Erase an AT45DB page. eraseDone will be signaled.
   * @param page Flash page to erase. Must be less than AT45_MAX_PAGES.
   * @param eraseKind How to handle the erase:
   *   <br><code>AT45_ERASE</code>: actually erase the page in the flash chip
   *   <br><code>AT45_DONT_ERASE</code>: don't erase the page in the flash 
   *     chip, but reserve a buffer for this page - subsequent writes to this
   *     page will be faster because the old contents need not be read
   *   <br><code>AT45_PREVIOUSLY_ERASED</code>: assume the page was previously
   *     erased in the flash and reserve a buffer for this page - subsequent
   *     writes to page will be faster because the old contents need not be 
   *     read and the write itself will be faster
   */
  command void erase(at45page_t page, uint8_t eraseKind);
  /**
   * Signal completion of an erase operation. 
   * @param error SUCCESS if the erase was successful, FAIL otherwise
   */
  event void eraseDone(error_t error);

  /**
   * Flush an AT45DB page from the buffers to the actual flash. syncDone
   * will be signaled once the flush has been completed and the buffer 
   * contents successfully compared with the flash. If the page is not
   * in the buffers, syncDone will succeed "immediately".
   * @param page Flash page to sync. Must be less than AT45_MAX_PAGES.
   */
  command void sync(at45page_t page);
  /**
   * Flush all AT45DB buffers to the actual flash. syncDone
   * will be signaled once the flush has been completed and the buffer 
   * contents successfully compared with the flash. 
   */
  command void syncAll();
  /**
   * Signal completion of a sync or syncAll operation. 
   * @param error SUCCESS if the sync was successful, FAIL otherwise
   */
  event void syncDone(error_t error);

  /**
   * Flush an AT45DB page from the buffers to the actual flash. flushDone
   * will be signaled once the flush has been initiated. If the page is not
   * in the buffers, flushDone will succeed "immediately".
   * @param page Flash page to sync. Must be less than AT45_MAX_PAGES.
   */
  command void flush(at45page_t page);
  /**
   * Flush all AT45DB buffers to the actual flash. flushDone
   * will be signaled once the flushes have been initiated. 
   */
  command void flushAll();
  /**
   * Signal completion of an flush or flushAll operation. 
   * @param error SUCCESS if the flush was successful, FAIL otherwise
   */
  event void flushDone(error_t error);

  /**
   * Read some data from an AT45DB page. readDone will be signaled.
   * @param page Flash page to read from. Must be less than AT45_MAX_PAGES.
   * @param offset Offset in page at which to start reading - must be between
   *   0 and AT45_PAGE_SIZE - 1 
   * @param data Buffer in which to place read data. The buffer is "returned"
   *   at readDone time.
   * @param n Number of bytes to read (> 0). offset + n must be <= 
   *   AT45_PAGE_SIZE
   */
  command void read(at45page_t page, at45pageoffset_t offset,
		    void *PASS COUNT(n) data, at45pageoffset_t n);
  /**
   * Signal completion of a read operation. The buffer passed to read
   * is implictly returned.
   * @param error SUCCESS for a successful read, FAIL otherwise
   */
  event void readDone(error_t error);

  /**
   * Compute the CRC of some data from an AT45DB page (using the CRC
   * function from crc.h). computeCrcDone will be signaled.
   * @param page Flash page to read from. Must be less than AT45_MAX_PAGES.
   * @param offset Offset in page at which to start reading - must be between
   *   0 and AT45_PAGE_SIZE - 1 
   * @param n Number of bytes to read (> 0). offset + n must be <= 
   *   AT45_PAGE_SIZE
   * @param baseCrc initial CRC value - use 0 if computing a "standalone"
   *   CRC, or a previous computeCrc result if computing a CRC over several
   *   flash pages
   */
  command void computeCrc(at45page_t page, at45pageoffset_t offset,
			  at45pageoffset_t n, uint16_t baseCrc);
  /**
   * Signal completion of a CRC computation.
   * @param error SUCCESS if the CRC was successfully computed, FAIL otherwise
   * @param crc CRC value (valid only if error == SUCCESS)
   */
  event void computeCrcDone(error_t error, uint16_t crc);
}
