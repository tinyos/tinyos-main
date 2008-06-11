/*
 * Copyright (c) 2002-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * HPL for Atmel's AT45DB family of serial dataflash chips. 
 * Provides access to all basic AT45DB operations plus operations to 
 * wait for the flash to go idle or finish a comparison. See the AT45DB
 * family datasheets for full details on these operations.
 * <p>
 * This interface only supports one operation at a time.
 *
 * @author David Gay
 */

#include "HplAt45db.h"

interface HplAt45db {
  /**
   * Wait for a "Group A" operation to complete (essentially all non-buffer
   * operations). You should use waitComapre if you are waiting for a
   * comparison to complete. waitIdleDone will be signaled when the operation
   * is complete.
   */
  command void waitIdle();

  /**
   * Signaled when the flash is idle.
   */
  event void waitIdleDone();

  /**
   * Wait for a buffer-flash comparison to complete. waitCompareDone will
   * be signaled when that occurs.
   */
  command void waitCompare();

  /**
   * Signaled when the buffer-flash comparison is complete.
   * @param compareOk TRUE if the comparison succeeded, FALSE otherwise.
   */
  event void waitCompareDone(bool compareOk);

  /**
   * Read a page from flash into a buffer. fillDone will be signaled.
   * @param cmd AT45_C_FILL_BUFFER1 to read into buffer 1, 
   *   AT45_C_FILL_BUFFER2 to read into buffer 2
   * @param page Page to read (must be less than AT45_MAX_PAGES)
   */
  command void fill(uint8_t cmd, at45page_t page);

  /**
   * Signaled when fill command sent (use waitIdle to detect when
   * fill command completes)
   */
  event void fillDone();

  /**
   * Write a buffer to a flash page. flushDone will be signaled.
   * @param cmd AT45_C_FLUSH_BUFFER1 to write buffer 1 to flash,
   *   AT45_C_FLUSH_BUFFER2 to write buffer 2 to flash,
   *   AT45_C_QFLUSH_BUFFER1 to write buffer 1 to flash w/o erase
   *   (page must have been previously erased),
   *   AT45_C_QFLUSH_BUFFER2 to write buffer 2 to flash w/o erase
   *   (page must have been previously erased),
   * @param page Page to write (must be less than AT45_MAX_PAGES)
   */
  command void flush(uint8_t cmd, at45page_t page);

  /**
   * Signaled when flush command sent (use waitIdle to detect when
   * flush command completes)
   */
  event void flushDone();

  /**
   * Compare a page from flash with a buffer. compareDone will be signaled.
   * @param cmd AT45_C_COMPARE_BUFFER1 to compare buffer 1, 
   *   AT45_C_COMPARE_BUFFER2 to compare buffer 2
   * @param page Page to compare with (must be less than AT45_MAX_PAGES)
   */
  command void compare(uint8_t cmd, at45page_t page);

  /**
   * Signaled when compare command sent (use waitCompare to detect when
   * compare command completes and find out comparison result)
   */
  event void compareDone();

  /**
   * Erase a flash page. eraseDone will be signaled.
   * @param cmd must be AT45_C_ERASE_PAGE
   * @param page Page to compare with (must be less than AT45_MAX_PAGES)
   */
  command void erase(uint8_t cmd, at45page_t page);

  /**
   * Signaled when erase command sent (use waitIdle to detect when
   * erase command completes)
   */
  event void eraseDone();

  /**
   * Read from a flash buffer. readDone will be signaled.
   * @param cmd AT45_C_READ_BUFFER1 to read from buffer 1,
   *   AT45_C_READ_BUFFER2 to read from buffer 2
   * @param offset Offset in page at which to start reading - must be between
   *   0 and AT45_PAGE_SIZE - 1 
   * @param data Buffer in which to place read data. The buffer is "returned"
   *   at readDone time.
   * @param n Number of bytes to read (> 0). offset + n must be <= 
   *   AT45_PAGE_SIZE
   */
  command void readBuffer(uint8_t cmd, at45pageoffset_t offset,
  		    uint8_t *PASS COUNT_NOK(n) data, uint16_t n);

  /**
   * Read directly from flash. readDone will be signaled.
   * @param cmd AT45_C_READ_CONTINUOUS or AT45_C_READ_PAGE. When the end of
   *   a page is read, AT45_C_READ_CONTINUOUS continues on the next page,
   *   while AT45_C_READ_PAGE continues at the start of the same page.
   * @param page Page to read from
   * @param offset Offset in page at which to start reading - must be between
   *   0 and AT45_PAGE_SIZE - 1 
   * @param data Buffer in which to place read data. The buffer is "returned"
   *   at readDone time.
   * @param n Number of bytes to read (> 0).
   */
  command void read(uint8_t cmd, at45page_t page, at45pageoffset_t offset,
  		    uint8_t *PASS COUNT_NOK(n) data, at45pageoffset_t n);

  /**
   * Signaled when data has been read from the buffer. The data buffer
   * is "returned".
   */
  event void readDone();

  /**
   * Compute CRC of data in a flash buffer (using the CRC function from crc.h).
   * crcDone will be signaled.
   * @param cmd AT45_C_READ_BUFFER1 to compute CRC from buffer 1,
   *   AT45_C_READ_BUFFER2 to compute CRC from buffer 2
   * @param page ignored (reserved for future use)
   * @param offset Offset in page at which to start reading - must be between
   *   0 and AT45_PAGE_SIZE - 1 
   * @param n Number of bytes to read (> 0). offset + n must be <= 
   *   AT45_PAGE_SIZE
   * @param baseCrc initial CRC value - use 0 if computing a "standalone"
   *   CRC, or a previous crc result if computing a CRC over several
   *   flash pages
   */
  command void crc(uint8_t cmd, at45page_t page, at45pageoffset_t offset,
		   at45pageoffset_t n, uint16_t baseCrc);
  /**
   * Signaled when CRC has been computed.
   * @param computedCrc CRC value
   */
  event void crcDone(uint16_t computedCrc);

  /**
   * Write some data to a flash buffer, and optionally the flash itself. 
   * writeDone will be signaled.
   * @param cmd One of AT45_C_WRITE_BUFFER1/2 or AT45_C_WRITE_MEM_BUFFER1/2
   *   to write respectively to buffer 1/2, or to buffer 1/2 and the 
   *   specified main memory page.
   * @param page Page to write when cmd is AT45_C_WRITE_MEM_BUFFER1/2
   * @param offset Offset in page at which to start writing - must be between
   *   0 and AT45_PAGE_SIZE - 1 
   * @param data Data to write. The buffer is "returned" at writeDone time.
   * @param n Number of bytes to write (> 0). offset + n must be <= 
   *   AT45_PAGE_SIZE
   */
  command void write(uint8_t cmd, at45page_t page, at45pageoffset_t offset,
  		     uint8_t *PASS COUNT_NOK(n) data, at45pageoffset_t n);

  /**
   * Signaled when data has been written to the buffer. The data buffer
   * is "returned".
   */
  event void writeDone();
}
