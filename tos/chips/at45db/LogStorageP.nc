/*									tab:4
 * "Copyright (c) 2000-2004 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

#include <Storage.h>
#include <crc.h>

/**
 * Private component of the AT45DB implementation of the log storage
 * abstraction.
 *
 * @author: David Gay <dgay@acm.org>
 * @author: Jonathan Hui <jwhui@cs.berkeley.edu>
 */

module LogStorageP {
  provides {
    interface LogRead[uint8_t logId];
    interface LogWrite[uint8_t logId];
  }
  uses {
    interface At45db;
    interface At45dbVolume[uint8_t logId];
    interface Resource[uint8_t logId];
  }
}
implementation
{
  /* Some design notes.

  - The logId's in the LogRead and LogWrites are shifted left by 1 bit.
    The low-order bit is 1 for circular logs, 0 for linear ones
    (see newRequest and endRequest, and the LogStorageC configuration)

  - Data is written sequentially to the pages of a log volume. Each page
    ends with a footer (nx_struct pageinfo) recording metadata on the
    current page:
    o a cookie
    o the "position" of the current page in the log (see below)
    o the offset of the last record on this page (i.e., the offset
      at which the last append ended) - only valid if flags & F_LASTVALID
    o flags: 
      x F_SYNC page was synchronised - data after lastRecordOffset
        is not log data; implies F_LASTVALID
      x F_CIRCLED this page is not from the first run through the log's
        pages (never set in linear logs)
      x F_LASTVALID not set if no record ended on this page
    o a CRC

  - "Positions" are stored in the metadata, used as cookies by
    currentOffset and seek, and stored in the wpos and rpos fields of the
    volume state structure.  They represent the number of bytes that
    writing has advanced in the log since the log was erased, with
    PAGE_SIZE added. Note that this is basically the number of bytes
    written, except that when a page is synchronised unused bytes in the
    page count towards increasing the position.

    As a result, on page p, the following equation holds:
      (metadata(p).pos - PAGE_SIZE) % volume-size == p * PAGE_SIZE
    (this also means that the "position" metadata field could be replaced
    by a count of the number of times writing has cycled through the log,
    reducing the metadata size)

    The PAGE_SIZE offset on positions is caused by Invariant 2 below: to
    ensure that Invariant 2 is respected, at flash erase time, we write a
    valid page with position 0 to the last block of the flash. As a result,
    the first writes to the flash, in page 0, are at "position" PAGE_SIZE.

  - This code is designed to deal with "one-at-a-time" failures (i.e.,
    the system will not modify any blocks after a previous failed
    write). This should allow recovery from:
    o arbitrary reboots
    o write failure (the underlying PageEEPROM shuts down after any
      write fails; all pages are flushed before moving on to the next
      page)
    It will not recover from arbitrary data corruption

  - When sync is called, the current write page is written to flash with an
    F_SYNC flag and writing continues on the next page (wasting on average
    half a flasg page)

  - We maintain the following invariants on log volumes, even in the face
    of the "one-at-a-time" failures described above:
    1) at least one of the first and last blocks are valid
    2) the last block, if valid, has the F_SYNC flag

  - Locating the log boundary page (the page with the greatest position):

    Invariant 1, the one-at-a-time failure model and the metadata position
    definition guarantees that the physical flash pages have the following
    properties:
      an initial set of V1 valid pages,
      followed by a set of I invalid pages,
      followed by a set of V2 valid pages
    with V1+i+V2=total-number-of-pages, and V1, V2, I >= 0
    Additionally, the position of all pages in V1 is greater than in V2,
    and consecutive pages in V1 (respectively V2) have greater positions
    than their predecessors.

    From this, it's possible to locate the log boundary page (the page with
    the greatest position) using the following algorithm:
    o let basepos=metadata(lastpage).pos, or 0 if the last page is invalid
    o locate (using a binary search) the page p with the largest position
      greater than basepos
      invalid pages can be assumed to have positions less than basepos
      if there is no such page p, let p = lastpage

    Once the log boundary page is known, we resume writing at the last
    page before p with a record boundary (Invariant 2, combined with
    limiting individual records to volumesize - PAGE_SIZE ensures there
    will be such a page).

  - The read pointer has a special "invalid" state which represents the
    current beginning of the log. In that state, LogRead.currentOffset()
    returns SEEK_BEGINNING rather than a regular position.

    The read pointer is invalidated:
    o at boot time
    o after the volume is erased
    o after the write position "catches up" with the read position
    o after a failed seek

    Reads from an invalid pointer:
    o start reading from the beginning of the flash if we are on the
      first run through the log volume
    o start reading at the first valid page after the write page with
      an F_LASTVALID flag; the read offset is set to the lastRecordOffset
      value
      if this page has the SYNC flag, we start at the beginning of the
      next page
  */
             

  enum {
    F_SYNC = 1,
    F_CIRCLED = 2,
    F_LASTVALID = 4
  };

  nx_struct pageinfo {
    nx_uint16_t magic;
    nx_uint32_t pos;
    nx_uint8_t lastRecordOffset;
    nx_uint8_t flags;
    nx_uint16_t crc;
  };

  enum {
    N = uniqueCount(UQ_LOG_STORAGE),
    NO_CLIENT = 0xff,
    PAGE_SIZE = AT45_PAGE_SIZE - sizeof(nx_struct pageinfo),
    PERSISTENT_MAGIC = 0x4256,
  };

  enum {
    R_IDLE,
    R_ERASE,
    R_APPEND,
    R_SYNC,
    R_READ,
    R_SEEK
  };

  enum {
    META_IDLE,
    META_LOCATEFIRST,
    META_LOCATE,
    META_LOCATELAST,
    META_SEEK,
    META_READ,
    META_WRITE
  };

  uint8_t client = NO_CLIENT;
  uint8_t metaState;
  bool recordsLost;
  at45page_t firstPage, lastPage;
  storage_len_t len;
  nx_struct pageinfo metadata;

  struct {
    /* The latest request made for this client, and it's arguments */
    uint8_t request; 
    uint8_t *buf;
    storage_len_t len;

    /* Log r/w positions */
    bool positionKnown : 1;
    bool circular : 1;
    bool circled : 1;
    bool rvalid : 1;
    uint32_t wpos;		/* Bytes since start of logging */
    at45page_t wpage;		/* Current write page */
    at45pageoffset_t woffset;	/* Offset on current write page */
    uint32_t rpos;		/* Bytes since start of logging */
    at45page_t rpage;		/* Current read page */
    at45pageoffset_t roffset;	/* Offset on current read page */
    at45pageoffset_t rend;	/* Last valid offset on current read page */
  } s[N];

  at45page_t firstVolumePage() {
    return call At45dbVolume.remap[client](0);
  }

  at45page_t npages() {
    return call At45dbVolume.volumeSize[client]();
  }

  at45page_t lastVolumePage() {
    return call At45dbVolume.remap[client](npages());
  }

  void setWritePage(at45page_t page) {
    if (s[client].circular && page == lastVolumePage())
      {
	s[client].circled = TRUE;
	page = firstVolumePage();
      }
    s[client].wpage = page;
    s[client].woffset = 0;
  }

  void invalidateReadPointer() {
    s[client].rvalid = FALSE;
  }

  void crcPage(at45page_t page) {
    call At45db.computeCrc(page, 0,
			   PAGE_SIZE + offsetof(nx_struct pageinfo, crc), 0);
  }

  void readMetadata(at45page_t page) {
    call At45db.read(page, PAGE_SIZE, &metadata, sizeof metadata);
  }

  void writeMetadata(at45page_t page) {
    call At45db.write(page, PAGE_SIZE, &metadata, sizeof metadata);
  }

  void wmetadataStart();

  void sync() {
    metadata.flags = F_SYNC | F_LASTVALID;
    metadata.lastRecordOffset = s[client].woffset;
    /* rend is now no longer the end of the page */
    if (s[client].rpage == s[client].wpage)
      s[client].rend = s[client].woffset;
    wmetadataStart();
  }

  /* ------------------------------------------------------------------ */
  /* Queue and initiate user requests					*/
  /* ------------------------------------------------------------------ */

  void eraseStart();
  void appendStart();
  void syncStart();
  void readStart();
  void locateStart();
  void rmetadataStart();
  void seekStart();

  void startRequest() {
    if (!s[client].positionKnown && s[client].request != R_ERASE)
      {
	locateStart();
	return;
      }

    metaState = META_IDLE;
    switch (s[client].request)
      {
      case R_ERASE: eraseStart(); break;
      case R_APPEND: appendStart(); break;
      case R_SYNC: syncStart(); break;
      case R_READ: readStart(); break;
      case R_SEEK: seekStart(); break;
      }
  }

  void endRequest(error_t ok) {
    uint8_t c = client;
    uint8_t request = s[c].request;
    storage_len_t actualLen = s[c].len - len;
    void *ptr = s[c].buf - actualLen;
    
    client = NO_CLIENT;
    s[c].request = R_IDLE;
    call Resource.release[c]();

    c = c << 1 | s[c].circular;
    switch (request)
      {
      case R_ERASE: signal LogWrite.eraseDone[c](ok); break;
      case R_APPEND: signal LogWrite.appendDone[c](ptr, actualLen, recordsLost, ok); break;
      case R_SYNC: signal LogWrite.syncDone[c](ok); break;
      case R_READ: signal LogRead.readDone[c](ptr, actualLen, ok); break;
      case R_SEEK: signal LogRead.seekDone[c](ok); break;
      }
  }

  /* Enqueue request and request the underlying flash */
  error_t newRequest(uint8_t newRequest, uint8_t id,
		     uint8_t *buf, storage_len_t length) {
    s[id >> 1].circular = id & 1;
    id >>= 1;

    if (s[id].request != R_IDLE)
      return EBUSY;

    s[id].request = newRequest;
    s[id].buf = buf;
    s[id].len = length;
    call Resource.request[id]();

    return SUCCESS;
  }

  event void Resource.granted[uint8_t id]() {
    client = id;
    len = s[client].len;
    startRequest();
  }

  command error_t LogWrite.append[uint8_t id](void* buf, storage_len_t length) {
    if (len > call LogRead.getSize[id]() - PAGE_SIZE)
      /* Writes greater than the volume size are invalid.
	 Writes equal to the volume size could break the log volume
	 invariant (see next comment).
	 Writes that span the whole volume could lead to problems
	 at boot time (no valid block with a record boundary).
	 Refuse them all. */
      return EINVAL;
    else
      return newRequest(R_APPEND, id, buf, length);
  }

  command storage_cookie_t LogWrite.currentOffset[uint8_t id]() {
    return s[id >> 1].wpos;
  }

  command error_t LogWrite.erase[uint8_t id]() {
    return newRequest(R_ERASE, id, NULL, 0);
  }

  command error_t LogWrite.sync[uint8_t id]() {
    return newRequest(R_SYNC, id, NULL, 0);
  }

  command error_t LogRead.read[uint8_t id](void* buf, storage_len_t length) {
    return newRequest(R_READ, id, buf, length);
  }

  command storage_cookie_t LogRead.currentOffset[uint8_t id]() {
    id >>= 1;
    return s[id].rvalid ? s[id].rpos : SEEK_BEGINNING;
  }

  command error_t LogRead.seek[uint8_t id](storage_cookie_t offset) {
    return newRequest(R_SEEK, id, (void *)((uint16_t)(offset >> 16)), offset);
  }

  command storage_len_t LogRead.getSize[uint8_t id]() {
    return call At45dbVolume.volumeSize[id >> 1]() * (storage_len_t)PAGE_SIZE;
  }

  /* ------------------------------------------------------------------ */
  /* Erase								*/
  /* ------------------------------------------------------------------ */

  void eraseMetadataDone() {
    /* Set write pointer to the beginning of the flash */
    s[client].wpos = PAGE_SIZE; // last page has offset 0 and is before us
    s[client].circled = FALSE;
    setWritePage(firstVolumePage()); 

    invalidateReadPointer();

    s[client].positionKnown = TRUE;
    endRequest(SUCCESS);
  }

  void eraseEraseDone() {
    if (firstPage == lastPage - 1)
      {
	/* We create a valid, synced last page (see invariants) */
	metadata.flags = F_SYNC | F_LASTVALID;
	metadata.lastRecordOffset = 0;
	setWritePage(firstPage);
	s[client].circled = FALSE;
	s[client].wpos = 0;
	wmetadataStart();
      }
    else
      call At45db.erase(firstPage++, AT45_ERASE);
  }

  void eraseStart() {
    s[client].positionKnown = FALSE; // in case erase fails
    firstPage = firstVolumePage();
    lastPage = lastVolumePage();
    eraseEraseDone();
  }

  /* ------------------------------------------------------------------ */
  /* Locate log boundaries						*/
  /* ------------------------------------------------------------------ */

  void locateLastRecord();

  void locateLastCrcDone(uint16_t crc) {
    if (crc != metadata.crc)
      {
	locateLastRecord();
	return;
      }

    /* We've found the last valid page with a record-end. Set up
       the read and write positions. */
    invalidateReadPointer();

    if (metadata.flags & F_SYNC) /* must start on next page */
      {
	/* We need to special case the empty log, as we don't want
	   to wrap around in the case of a full, non-circular log
	   with a sync on its last page. */
	if (firstPage == lastPage && !metadata.pos)
	  setWritePage(firstVolumePage());
	else
	  setWritePage(firstPage + 1);
	s[client].wpos = metadata.pos + PAGE_SIZE;
      }
    else
      {
	s[client].wpage = firstPage;
	s[client].woffset = metadata.lastRecordOffset;
	s[client].wpos = metadata.pos + metadata.lastRecordOffset;
      }

    s[client].circled = (metadata.flags & F_CIRCLED) != 0;
    if (s[client].circled && !s[client].circular) // oops
      {
	endRequest(FAIL);
	return;
      }

    /* And we can now proceed to the real request */
    s[client].positionKnown = TRUE;
    startRequest();
  }

  void locateLastReadDone() {
    if (metadata.magic == PERSISTENT_MAGIC && metadata.flags & F_LASTVALID)
      crcPage(firstPage);
    else
      locateLastRecord();
  }

  void locateLastRecord() {
    if (firstPage == lastPage)
      {
	/* We walked all the way back to the last page, and it's not 
	   valid. The log-volume invariant is not holding. Fail out. */
	endRequest(FAIL);
	return;
      }

    if (firstPage == firstVolumePage())
      firstPage = lastPage;
    else
      firstPage--;

    readMetadata(firstPage);
  }

  void located() {
    metaState = META_LOCATELAST;
    /* firstPage is one after last valid page, but the last page with
       a record end may be some pages earlier. Search for it. */
    lastPage = lastVolumePage() - 1;
    locateLastRecord();
  }

  at45page_t locateCurrentPage() {
    return firstPage + ((lastPage - firstPage) >> 1);
  }

  void locateBinarySearch() {
    if (lastPage <= firstPage)
      located();
    else
      readMetadata(locateCurrentPage());
  }

  void locateGreaterThan() {
    firstPage = locateCurrentPage() + 1;
    locateBinarySearch();
  }

  void locateLessThan() {
    lastPage = locateCurrentPage();
    locateBinarySearch();
  }

  void locateCrcDone(uint16_t crc) {
    if (crc == metadata.crc)
      {
	s[client].wpos = metadata.pos;
	locateGreaterThan();
      }
    else
      locateLessThan();
  }

  void locateReadDone() {
    if (metadata.magic == PERSISTENT_MAGIC && s[client].wpos < metadata.pos)
      crcPage(locateCurrentPage());
    else
      locateLessThan();
  }

  void locateFirstCrcDone(uint16_t crc) {
    if (metadata.magic == PERSISTENT_MAGIC && crc == metadata.crc)
      s[client].wpos = metadata.pos;
    else
      s[client].wpos = 0;

    metaState = META_LOCATE;
    locateBinarySearch();
  }

  void locateFirstReadDone() {
    crcPage(lastPage);
  }

  /* Locate log beginning and ending. See description at top of file. */
  void locateStart() {
    metaState = META_LOCATEFIRST;
    firstPage = firstVolumePage();
    lastPage = lastVolumePage() - 1;
    readMetadata(lastPage);
  }

  /* ------------------------------------------------------------------ */
  /* Append								*/
  /* ------------------------------------------------------------------ */

  void appendContinue() {
    uint8_t *buf = s[client].buf;
    at45pageoffset_t offset = s[client].woffset, count;
    
    if (len == 0)
      {
	endRequest(SUCCESS);
	return;
      }

    if (s[client].wpage == lastVolumePage())
      {
	/* We reached the end of a linear log */
	endRequest(ESIZE);
	return;
      }

    if (offset + len <= PAGE_SIZE)
      count = len;
    else
      count = PAGE_SIZE - offset;

    s[client].buf += count;
    s[client].wpos += count;
    s[client].woffset += count;
    len -= count;

    /* We normally lose data at the point we make the first write to a
       page in a log that has circled. */
    if (offset == 0 && s[client].circled)
      recordsLost = TRUE;

    call At45db.write(s[client].wpage, offset, buf, count);
  }
  
  void appendWriteDone() {
    if (s[client].woffset == PAGE_SIZE) /* Time to write metadata */
      wmetadataStart();
    else
      endRequest(SUCCESS);
  }

  void appendMetadataDone() { // metadata of previous page flushed
    /* Setup metadata in case we overflow this page too */
    metadata.flags = 0;
    appendContinue();
  }

  void appendSyncDone() {
    s[client].wpos = metadata.pos + PAGE_SIZE;
    appendStart();
  }

  void appendStart() {
    storage_len_t vlen = (storage_len_t)npages() * PAGE_SIZE;

    recordsLost = FALSE;

    /* If request would span the end of the flash, sync, to maintain the
       invariant that the last flash page is synced and that either
       the first or last pages are valid.

       Note that >= in the if below means we won't write a record that
       would end on the last byte of the last page, as this would mean that
       we would not sync the last page, breaking the log volume
       invariant */
    if ((s[client].wpos - PAGE_SIZE) % vlen >= vlen - len)
      sync();
    else
      {
	/* Set lastRecordOffset in case we need to write metadata (see
	   wmetadataStart) */
	metadata.lastRecordOffset = s[client].woffset;
	metadata.flags = F_LASTVALID;
	appendContinue();
      }
  }

  /* ------------------------------------------------------------------ */
  /* Sync								*/
  /* ------------------------------------------------------------------ */

  void syncStart() {
    if (s[client].woffset == 0) /* we can't lose any writes */
      endRequest(SUCCESS);
    else
      sync();
  }

  void syncMetadataDone() {
    /* Write position reflect the absolute position in the flash, not
       user-bytes written. So update wpos to reflect sync effects. */
    s[client].wpos = metadata.pos + PAGE_SIZE;
    endRequest(SUCCESS);
  }

  /* ------------------------------------------------------------------ */
  /* Write block metadata						*/
  /* ------------------------------------------------------------------ */

  void wmetadataStart() {
    /* The caller ensures that metadata.flags (except F_CIRCLED) and
       metadata.lastRecordOffset are set correctly. */
    metaState = META_WRITE;
    firstPage = s[client].wpage; // remember page to commit
    metadata.pos = s[client].wpos - s[client].woffset;
    metadata.magic = PERSISTENT_MAGIC;
    if (s[client].circled)
      metadata.flags |= F_CIRCLED;

    call At45db.computeCrc(firstPage, 0, PAGE_SIZE, 0);

    /* We move to the next page now. If writing the metadata fails, we'll
       simply leave the invalid page in place. Trying to recover seems
       complicated, and of little benefit (note that in practice, At45dbC
       shuts down after a failed write, so nothing is really going to
       happen after that anyway). */
    setWritePage(s[client].wpage + 1);

    /* Invalidate read pointer if we reach it's page */
    if (s[client].wpage == s[client].rpage)
      invalidateReadPointer();
  }

  void wmetadataCrcDone(uint16_t crc) {
    uint8_t i, *md;

    // Include metadata in crc
    md = (uint8_t *)&metadata;
    for (i = 0; i < offsetof(nx_struct pageinfo, crc); i++)
      crc = crcByte(crc, md[i]);
    metadata.crc = crc;

    // And save it
    writeMetadata(firstPage);
  }

  void wmetadataWriteDone() {
    metaState = META_IDLE;
    if (metadata.flags & F_SYNC)
      call At45db.sync(firstPage);
    else
      call At45db.flush(firstPage);
  }

  /* ------------------------------------------------------------------ */
  /* Read 								*/
  /* ------------------------------------------------------------------ */

  void readContinue() {
    uint8_t *buf = s[client].buf;
    at45pageoffset_t offset = s[client].roffset, count;
    at45pageoffset_t end = s[client].rend;
    
    if (len == 0)
      {
	endRequest(SUCCESS);
	return;
      }

    if (!s[client].rvalid)
      {
	if (s[client].circled)
	  /* Find a valid page after wpage, skipping invalid pages */
	  s[client].rpage = s[client].wpage;
	else
	  {
	    /* resume reading at the beginning of the first page */
	    s[client].rvalid = TRUE;
	    s[client].rpage = lastVolumePage() - 1;
	  }

	rmetadataStart();
	return;
      }

    if (s[client].rpage == s[client].wpage)
      end = s[client].woffset;

    if (offset == end)
      {
	if ((s[client].rpage + 1 == lastVolumePage() && !s[client].circular) ||
	    s[client].rpage == s[client].wpage)
	  endRequest(SUCCESS); // end of log
	else
	  rmetadataStart();
	return;
      }

    if (offset + len <= end)
      count = len;
    else
      count = end - offset;

    s[client].buf += count;
    len -= count;
    s[client].rpos += count;
    s[client].roffset = offset + count;

    call At45db.read(s[client].rpage, offset, buf, count);
  }

  void readStart() {
    readContinue();
  }

  /* ------------------------------------------------------------------ */
  /* Read block metadata						*/
  /* ------------------------------------------------------------------ */

  void continueReadAt(at45pageoffset_t roffset) {
    /* Resume reading at firstPage whose metadata is currently available
       in the metadata variable */
    metaState = META_IDLE;
    s[client].rpos = metadata.pos + roffset;
    s[client].rpage = firstPage;
    s[client].roffset = roffset;
    s[client].rend =
      metadata.flags & F_SYNC ? metadata.lastRecordOffset : PAGE_SIZE;
    s[client].rvalid = TRUE;
    readContinue();
  }

  void rmetadataContinue() {
    if (++firstPage == lastVolumePage())
      firstPage = firstVolumePage();
    if (firstPage == s[client].wpage)
      if (!s[client].rvalid)
	/* We cannot find a record boundary to start at (we've just
	   walked through the whole log...). Give up. */
	endRequest(SUCCESS);
      else
	{
	  /* The current write page has no metadata yet, so we fake it */
	  metadata.flags = 0;
	  metadata.pos = s[client].wpos - s[client].woffset;
	  continueReadAt(0);
	}
    else
      readMetadata(firstPage);
  }

  void rmetadataReadDone() {
    if (metadata.magic == PERSISTENT_MAGIC)
      crcPage(firstPage);
    else
      endRequest(SUCCESS);
  }

  void rmetadataCrcDone(uint16_t crc) {
    if (!s[client].rvalid)
      if (crc == metadata.crc && metadata.flags & F_LASTVALID)
	continueReadAt(metadata.lastRecordOffset);
      else
	rmetadataContinue();
    else 
      if (crc == metadata.crc)
	continueReadAt(0);
      else
	endRequest(SUCCESS);
  }

  void rmetadataStart() {
    metaState = META_READ;
    firstPage = s[client].rpage;
    rmetadataContinue();
  }

  /* ------------------------------------------------------------------ */
  /* Seek.								*/
  /* ------------------------------------------------------------------ */

  void seekCrcDone(uint16_t crc) {
    if (metadata.magic == PERSISTENT_MAGIC && crc == metadata.crc &&
	metadata.pos == s[client].rpos - s[client].roffset)
      {
	s[client].rvalid = TRUE;
	if (metadata.flags & F_SYNC)
	  s[client].rend = metadata.lastRecordOffset;
      }
    endRequest(SUCCESS);
  }

  void seekReadDone() {
    crcPage(s[client].rpage);
  }

  /* Move to position specified by cookie. */
  void seekStart() {
    uint32_t offset = (uint32_t)(uint16_t)s[client].buf << 16 | s[client].len;

    invalidateReadPointer(); // default to beginning of log

    /* The write positions are offset by PAGE_SIZE (see emptyLog) */

    if (offset == SEEK_BEGINNING)
      offset = PAGE_SIZE;

    if (offset > s[client].wpos || offset < PAGE_SIZE)
      {
	endRequest(EINVAL);
	return;
      }

    /* Cookies are just flash positions which continue incrementing as
       you circle around and around. So we can just check the requested
       page's metadata.pos field matches the cookie's value */
    s[client].rpos = offset;
    s[client].roffset = (offset - PAGE_SIZE) % PAGE_SIZE;
    s[client].rpage = firstVolumePage() + ((offset - PAGE_SIZE) / PAGE_SIZE) % npages();
    s[client].rend = PAGE_SIZE; // default to no sync flag

    // The last page's metadata isn't written to flash yet. Special case it.
    if (s[client].rpage == s[client].wpage)
      {
	/* If we're seeking within the current write page, just go there.
	   Otherwise, we're asking for an old version of the current page
	   so just keep the invalidated read pointer, i.e., read from
	   the beginning. */
	if (offset >= s[client].wpos - s[client].woffset)
	  s[client].rvalid = TRUE;
	endRequest(SUCCESS);
      }
    else
      {
	metaState = META_SEEK;
	readMetadata(s[client].rpage);
      }
  }

  /* ------------------------------------------------------------------ */
  /* Dispatch HAL operations to current user op				*/
  /* ------------------------------------------------------------------ */

  event void At45db.eraseDone(error_t error) {
    if (client != NO_CLIENT)
      if (error != SUCCESS)
	endRequest(FAIL);
      else
	eraseEraseDone();
  }

  event void At45db.writeDone(error_t error) {
    if (client != NO_CLIENT)
      if (error != SUCCESS)
	endRequest(FAIL);
      else
	switch (metaState)
	  {
	  case META_WRITE: wmetadataWriteDone(); break;
	  case META_IDLE: appendWriteDone(); break;
	  }
  }

  event void At45db.syncDone(error_t error) {
    if (client != NO_CLIENT)
      if (error != SUCCESS)
	endRequest(FAIL);
      else switch (s[client].request)
	{
	case R_ERASE: eraseMetadataDone(); break;
	case R_APPEND: appendSyncDone(); break;
	case R_SYNC: syncMetadataDone(); break;
	}
  }

  event void At45db.flushDone(error_t error) {
    if (client != NO_CLIENT)
      if (error != SUCCESS)
	endRequest(FAIL);
      else
	appendMetadataDone();
  }

  event void At45db.readDone(error_t error) {
    if (client != NO_CLIENT)
      if (error != SUCCESS)
	endRequest(FAIL);
      else
	switch (metaState)
	  {
	  case META_LOCATEFIRST: locateFirstReadDone(); break;
	  case META_LOCATE: locateReadDone(); break;
	  case META_LOCATELAST: locateLastReadDone(); break;
	  case META_SEEK: seekReadDone(); break;
	  case META_READ: rmetadataReadDone(); break;
	  case META_IDLE: readContinue(); break;
	  }					    
  }

  event void At45db.computeCrcDone(error_t error, uint16_t crc) {
    if (client != NO_CLIENT)
      if (error != SUCCESS)
	endRequest(FAIL);
      else
	switch (metaState)
	  {
	  case META_LOCATEFIRST: locateFirstCrcDone(crc); break;
	  case META_LOCATE: locateCrcDone(crc); break;
	  case META_LOCATELAST: locateLastCrcDone(crc); break;
	  case META_SEEK: seekCrcDone(crc); break;
	  case META_WRITE: wmetadataCrcDone(crc); break;
	  case META_READ: rmetadataCrcDone(crc); break;
	  }
  }

  event void At45db.copyPageDone(error_t error) { }

  default event void LogWrite.appendDone[uint8_t logId](void* buf, storage_len_t l, bool rLost, error_t error) { }
  default event void LogWrite.eraseDone[uint8_t logId](error_t error) { }
  default event void LogWrite.syncDone[uint8_t logId](error_t error) { }
  default event void LogRead.readDone[uint8_t logId](void* buf, storage_len_t l, error_t error) { }
  default event void LogRead.seekDone[uint8_t logId](error_t error) {}

  default command at45page_t At45dbVolume.remap[uint8_t logId](at45page_t volumePage) {return 0;}
  default command at45page_t At45dbVolume.volumeSize[uint8_t logId]() {return 0;}
  default async command error_t Resource.request[uint8_t logId]() {return SUCCESS;}
  default async command error_t Resource.release[uint8_t logId]() { return FAIL; }
}
