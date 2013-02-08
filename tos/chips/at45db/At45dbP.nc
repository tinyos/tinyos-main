// $Id: At45dbP.nc,v 1.11 2010-06-29 22:07:43 scipio Exp $

/*
 * Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * - Neither the name of the University of California nor the names of
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
 *
 * Copyright (c) 2002-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

#include "crc.h"
#include "At45db.h"
#include "Timer.h"

/**
 * Private componenent for the Atmel's AT45DB HAL.
 *
 * @author David Gay
 */

module At45dbP @safe() {
  provides {
    interface Init;
    interface At45db;
  }
  uses {
    interface HplAt45db;
    interface BusyWait<TMicro, uint16_t>;
  }
}
implementation
{
#define CHECKARGS

#if 0
  uint8_t work[20];
  uint8_t woffset;

  void wdbg(uint8_t x) {
    work[woffset++] = x;
    if (woffset == sizeof work)
      woffset = 0;
  }
#else
#define wdbg(n)
#endif

  enum { // requests
    IDLE,
    R_READ,
    R_READCRC,
    R_WRITE,
    R_ERASE,
    R_COPY,
    R_SYNC,
    R_SYNCALL,
    R_FLUSH,
    R_FLUSHALL,
    BROKEN // Write failed. Fail all subsequent requests.
  };
  uint8_t request;
  at45pageoffset_t reqOffset, reqBytes;
  uint8_t * COUNT_NOK(reqBytes) reqBuf;
  at45page_t reqPage;

  enum {
    P_READ,
    P_READCRC,
    P_WRITE,
    P_FLUSH,
    P_FILL,
    P_ERASE,
    P_COMPARE,
    P_COMPARE_CHECK
  };
  
  struct {
    at45page_t page;
    bool busy : 1;
    bool clean : 1;
    bool erased : 1;
    uint8_t unchecked : 2;
  } buffer[2];
  uint8_t selected; // buffer used by the current op
  uint8_t checking;
  bool flashBusy;

  // Select a command for the current buffer
#define OPN(n, name) ((n) ? name ## 1 : name ## 2)
#define OP(name) OPN(selected, name)

  command error_t Init.init() {
    request = IDLE;
    flashBusy = TRUE;
      
    // pretend we're on an invalid non-existent page
    buffer[0].page = buffer[1].page = AT45_MAX_PAGES;
    buffer[0].busy = buffer[1].busy = FALSE;
    buffer[0].clean = buffer[1].clean = TRUE;
    buffer[0].unchecked = buffer[1].unchecked = 0;
    buffer[0].erased = buffer[1].erased = FALSE;

    return SUCCESS;
  }
  
  void flashIdle() {
    flashBusy = buffer[0].busy = buffer[1].busy = FALSE;
  }

  void requestDone(error_t result, uint16_t computedCrc, uint8_t newState);
  void handleRWRequest();

  task void taskSuccess() {
    requestDone(SUCCESS, 0, IDLE);
  }
  task void taskFail() {
    requestDone(FAIL, 0, IDLE);
  }

  void checkBuffer(uint8_t buf) {
    if (flashBusy)
      {
	call HplAt45db.waitIdle();
	return;
      }
    call HplAt45db.compare(OPN(buf, AT45_C_COMPARE_BUFFER), buffer[buf].page);
    checking = buf;
  }

  void flushBuffer() {
    if (flashBusy)
      {
	call HplAt45db.waitIdle();
	return;
      }
    call HplAt45db.flush(buffer[selected].erased ?
			 OP(AT45_C_QFLUSH_BUFFER) :
			 OP(AT45_C_FLUSH_BUFFER), 
			 buffer[selected].page);
  }

  event void HplAt45db.waitIdleDone() {
    flashIdle();
    // Eager compare - this steals the current command
#if 0
    if ((buffer[0].unchecked || buffer[1].unchecked) &&
	cmdPhase != P_COMPARE)
      checkBuffer(buffer[0].unchecked ? 0 : 1);
    else
#endif
      handleRWRequest();
  }

  event void HplAt45db.waitCompareDone(bool ok) {
    flashIdle();

    if (ok)
      buffer[checking].unchecked = 0;
    else if (buffer[checking].unchecked < 2)
      buffer[checking].clean = FALSE;
    else
      {
	requestDone(FAIL, 0, BROKEN);
	return;
      }
    handleRWRequest();
  }

  event void HplAt45db.readDone() {
    requestDone(SUCCESS, 0, IDLE);
  }

  event void HplAt45db.writeDone() {
    buffer[selected].clean = FALSE;
    buffer[selected].unchecked = 0;
    requestDone(SUCCESS, 0, IDLE);
  }

  event void HplAt45db.crcDone(uint16_t crc) {
    requestDone(SUCCESS, crc, IDLE);
  }

  event void HplAt45db.flushDone() {
    flashBusy = TRUE;
    buffer[selected].clean = buffer[selected].busy = TRUE;
    buffer[selected].unchecked++;
    buffer[selected].erased = FALSE;
    handleRWRequest();
  }

  event void HplAt45db.compareDone() {
    flashBusy = TRUE;
    buffer[checking].busy = TRUE;
    // The 10us wait makes old mica motes (Atmega 103) happy, for
    // some mysterious reason (w/o this wait, the first compare
    // always fails, even though the compare after the rewrite
    // succeeds...)
    call BusyWait.wait(10);
    call HplAt45db.waitCompare();
  }

  event void HplAt45db.fillDone() {
    flashBusy = TRUE;
    buffer[selected].page = reqPage;
    buffer[selected].clean = buffer[selected].busy = TRUE;
    buffer[selected].erased = FALSE;
    handleRWRequest();
  }

  event void HplAt45db.eraseDone() {
    flashBusy = TRUE;
    // The buffer contains garbage, but we don't care about the state
    // of bits on this page anyway (if we do, we'll perform a 
    // subsequent write)
    buffer[selected].page = reqPage;
    buffer[selected].clean = TRUE;
    buffer[selected].erased = TRUE;
    requestDone(SUCCESS, 0, IDLE);
  }

  void syncOrFlushAll(uint8_t newReq);

  void handleRWRequest() {
    if (reqPage == buffer[selected].page)
      switch (request)
	{
	case R_ERASE:
	  switch (reqOffset)
	    {
	    case AT45_ERASE:
	      if (flashBusy)
		call HplAt45db.waitIdle();
	      else
		call HplAt45db.erase(AT45_C_ERASE_PAGE, reqPage);
	      break;
	    case AT45_PREVIOUSLY_ERASED:
	      // We believe the user...
	      buffer[selected].erased = TRUE;
	      /* Fallthrough */
	    case AT45_DONT_ERASE:
	      // The buffer contains garbage, but we don't care about the state
	      // of bits on this page anyway (if we do, we'll perform a 
	      // subsequent write)
	      buffer[selected].clean = TRUE;
	      requestDone(SUCCESS, 0, IDLE);
	      break;
	    }
	  break;

	case R_COPY:
	  if (!buffer[selected].clean) // flush any modifications
	    flushBuffer();
	  else
	    {
	      // Just redesignate as destination page, and mark it dirty.
	      // It will eventually be flushed, completing the copy.
	      buffer[selected].page = reqOffset;
	      buffer[selected].clean = FALSE;
	      post taskSuccess();
	    }
	  break;

	case R_SYNC: case R_SYNCALL:
	  if (buffer[selected].clean && buffer[selected].unchecked)
	    {
	      checkBuffer(selected);
	      return;
	    }
	  /* fall through */
	case R_FLUSH: case R_FLUSHALL:
	  if (!buffer[selected].clean)
	    flushBuffer();
	  else if (request == R_FLUSH || request == R_SYNC)
	    post taskSuccess();
	  else
	    {
	      // Check for more dirty pages
	      uint8_t oreq = request;

	      request = IDLE;
	      syncOrFlushAll(oreq);
	    }
	  break;

	case R_READ:
	  if (buffer[selected].busy)
	    call HplAt45db.waitIdle();
	  else
	    if (!buffer[selected].clean || buffer[selected].erased)
	      call HplAt45db.fill(OP(AT45_C_FILL_BUFFER), reqPage);
	    else
	      call HplAt45db.readBuffer(OP(AT45_C_READ_BUFFER), reqOffset,
				      reqBuf, reqBytes);
	  break;

	case R_READCRC:
	  if (buffer[selected].busy)
	    call HplAt45db.waitIdle();
	  else
	    /* Hack: baseCrc was stored in reqBuf */
	    call HplAt45db.crc(OP(AT45_C_READ_BUFFER), 0, reqOffset, reqBytes,
			       (uint16_t)reqBuf);
	  break;

	case R_WRITE:
	  if (buffer[selected].busy)
	    call HplAt45db.waitIdle();
	  else
	    call HplAt45db.write(OP(AT45_C_WRITE_BUFFER), 0, reqOffset,
				 reqBuf, reqBytes);
	  break;
	}
    else if (!buffer[selected].clean)
      flushBuffer();
    else if (buffer[selected].unchecked)
      checkBuffer(selected);
    else
      {
	// just get the new page (except for erase)
	if (request == R_ERASE)
	  {
	    buffer[selected].page = reqPage;
	    handleRWRequest();
	  }
	else if (flashBusy)
	  call HplAt45db.waitIdle();
	else
	  call HplAt45db.fill(OP(AT45_C_FILL_BUFFER), reqPage);
      }
  }

  void requestDone(error_t result, uint16_t computedCrc, uint8_t newState) {
    uint8_t orequest = request;

    request = newState;
    switch (orequest)
      {
      case R_READ: signal At45db.readDone(result); break;
      case R_READCRC: signal At45db.computeCrcDone(result, computedCrc); break;
      case R_WRITE: signal At45db.writeDone(result); break;
      case R_SYNC: case R_SYNCALL: signal At45db.syncDone(result); break;
      case R_FLUSH: case R_FLUSHALL: signal At45db.flushDone(result); break;
      case R_ERASE: signal At45db.eraseDone(result); break;
      case R_COPY: signal At45db.copyPageDone(result); break;
      }
  }

  void newRequest(uint8_t req, at45page_t page, at45pageoffset_t offset,
		  void * COUNT_NOK(n) reqdata, at45pageoffset_t n) {
    request = req;

    reqBuf = NULL;
    reqBytes = n;
    reqBuf = reqdata;
    reqPage = page;
    reqOffset = offset;

    if (page == buffer[0].page)
      selected = 0;
    else if (page == buffer[1].page)
      selected = 1;
    else
      selected = !selected; // LRU with 2 buffers...

#ifdef CHECKARGS
    if (page >= AT45_MAX_PAGES ||
	n > AT45_PAGE_SIZE ||
	(req != R_COPY && offset >= AT45_PAGE_SIZE) ||
	(req != R_COPY && offset + n > AT45_PAGE_SIZE) ||
	(req == R_COPY && offset >= AT45_MAX_PAGES)) {
      post taskFail();
    }
    else
#endif
      handleRWRequest();
  }

  command void At45db.read(at45page_t page, at45pageoffset_t offset,
				   void *reqdata, at45pageoffset_t n) {
    newRequest(R_READ, page, offset, reqdata, n);
  }

  command void At45db.computeCrc(at45page_t page,
					at45pageoffset_t offset,
					at45pageoffset_t n,
					uint16_t baseCrc) {
    /* This is a hack (store crc in reqBuf), but it saves 2 bytes of RAM */
    newRequest(R_READCRC, page, offset, TCAST(uint8_t * COUNT(n), baseCrc), n);
  }

  command void At45db.write(at45page_t page, at45pageoffset_t offset,
				    void *reqdata, at45pageoffset_t n) {
    newRequest(R_WRITE, page, offset, reqdata, n);
  }


  command void At45db.erase(at45page_t page, uint8_t eraseKind) {
    newRequest(R_ERASE, page, eraseKind, NULL, 0);
  }

  command void At45db.copyPage(at45page_t from, at45page_t to) {
    /* Assumes at45pageoffset_t can hold an at45page_t. A little icky */
    newRequest(R_COPY, from, to, NULL, 0);
  }

  void syncOrFlush(at45page_t page, uint8_t newReq) {
    request = newReq;

    if (buffer[0].page == page)
      selected = 0;
    else if (buffer[1].page == page)
      selected = 1;
    else
      {
	post taskSuccess();
	return;
      }

    buffer[selected].unchecked = 0;
    handleRWRequest();
  }

  command void At45db.sync(at45page_t page) {
    syncOrFlush(page, R_SYNC);
  }

  command void At45db.flush(at45page_t page) {
    syncOrFlush(page, R_FLUSH);
  }

  void syncOrFlushAll(uint8_t newReq) {
    request = newReq;

    if (!buffer[0].clean)
      selected = 0;
    else if (!buffer[1].clean)
      selected = 1;
    else
      {
	post taskSuccess();
	return;
      }

    buffer[selected].unchecked = 0;
    handleRWRequest();
  }

  command void At45db.syncAll() {
    syncOrFlushAll(R_SYNCALL);
  }

  command void At45db.flushAll() {
    syncOrFlushAll(R_FLUSHALL);
  }
}
