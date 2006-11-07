/*
 * Copyright (c) 2005-2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * Generic byte-at-a-time implementation of the AT45DB HPL.
 * 
 * Each platform must provide its own HPL implementation for its AT45DB
 * flash chip. To simplify this task, this component can easily be used to
 * build an AT45DB HPL by connecting it to a byte-at-a-time SPI interface,
 * and an HplAt45dbByte interface.
 *
 * @param The number of bits needed to represent a sector size, e.g., 9
 *   for the AT45DB041B.
 *
 * @author David Gay
 */

generic module HplAt45dbByteC(int sectorSizeLog2) {
  provides interface HplAt45db;
  uses {
    interface Resource;
    interface SpiByte as FlashSpi;
    interface HplAt45dbByte;
  }
}
implementation 
{
  enum {
    P_IDLE,
    P_SEND_CMD, 
    P_READ,
    P_READ_CRC,
    P_WRITE,
    P_WAIT_IDLE,
    P_WAIT_COMPARE,
    P_WAIT_COMPARE_OK,
    P_FILL,
    P_FLUSH,
    P_COMPARE,
    P_ERASE
  };
  uint8_t status = P_IDLE;
  uint8_t flashCmd[4];
  uint8_t *data;
  at45pageoffset_t dataCount;
  uint8_t dontCare;

  void complete(uint16_t crc) {
    uint8_t s = status;

    status = P_IDLE;
    switch (s)
      {
      default: break;
      case P_READ_CRC:
	signal HplAt45db.crcDone(crc);
	break;
      case P_FILL:
	signal HplAt45db.fillDone();
	break;
      case P_FLUSH:
	signal HplAt45db.flushDone();
	break;
      case P_COMPARE:
	signal HplAt45db.compareDone();
	break;
      case P_ERASE:
	signal HplAt45db.eraseDone();
	break;
      case P_READ:
	signal HplAt45db.readDone();
	break;
      case P_WRITE:
	signal HplAt45db.writeDone();
	break;
      }
  }

  void requestFlashStatus() {
    call HplAt45dbByte.select();
    call FlashSpi.write(AT45_C_REQ_STATUS);
    call HplAt45dbByte.waitIdle();
  }

  void doCommand() {
    uint8_t in = 0, out = 0;
    uint8_t *ptr;
    at45pageoffset_t count;
    uint8_t lphase;
    uint16_t crc = (uint16_t)data;

    if (dataCount) // skip 0-byte ops
      {
	/* For a 3% speedup, we could use labels and goto *.
	   But: very gcc-specific. Also, need to do
	   asm ("ijmp" : : "z" (state))
	   instead of goto *state
	*/

	ptr = flashCmd;
	lphase = P_SEND_CMD;
	count = 4 + dontCare;

	call HplAt45dbByte.select();
	for (;;)
	  {
	    if (lphase == P_READ_CRC)
	      {
		crc = crcByte(crc, in);

		--count;
		if (!count)
		  break;
	      }
	    else if (lphase == P_SEND_CMD)
	      {
		// Note: the dontCare bytes are read after the end of cmd...
		out = *ptr++;
		count--;
		if (!count)
		  {
		    lphase = status;
		    ptr = data;
		    count = dataCount;
		  }
	      }
	    else if (lphase == P_READ)
	      {
		*ptr++ = in;
		--count;
		if (!count)
		  break;
	      }
	    else if (lphase == P_WRITE)
	      {
		if (!count)
		  break;

		out = *ptr++;
		--count;
	      }
	    else /* P_COMMAND */
	      break;
	
	    in = call FlashSpi.write(out);
	  }
	call HplAt45dbByte.deselect();
      }

    call Resource.release();
    complete(crc);
  }

  event void Resource.granted() {
    switch (status)
      {
      case P_WAIT_COMPARE: case P_WAIT_IDLE:
	requestFlashStatus();
	break;
      default:
	doCommand();
	break;
      }
  }

  void execCommand(uint8_t op, uint8_t reqCmd, uint8_t reqDontCare,
		   at45page_t reqPage, at45pageoffset_t reqOffset,
		   uint8_t *reqData, at45pageoffset_t reqCount) {
    status = op;

    // page (2 bytes) and highest bit of offset
    flashCmd[0] = reqCmd;
    flashCmd[1] = reqPage >> (16 - sectorSizeLog2);
    flashCmd[2] = reqPage << (sectorSizeLog2 - 8) | reqOffset >> 8;
    flashCmd[3] = reqOffset; // low-order 8 bits
    data = reqData;
    dataCount = reqCount;
    dontCare = reqDontCare;

    call Resource.request();
  }

  command void HplAt45db.waitIdle() {
    status = P_WAIT_IDLE;
    call Resource.request();
  }

  command void HplAt45db.waitCompare() {
    status = P_WAIT_COMPARE;
    call Resource.request();
  }

  event void HplAt45dbByte.idle() {
    if (status == P_WAIT_COMPARE)
      {
	bool cstatus = call HplAt45dbByte.getCompareStatus();
	call HplAt45dbByte.deselect();
	call Resource.release();
	signal HplAt45db.waitCompareDone(cstatus);
      }
    else
      {
	call HplAt45dbByte.deselect();
	call Resource.release();
	signal HplAt45db.waitIdleDone();
      }
  }

  command void HplAt45db.fill(uint8_t cmd, at45page_t page) {
    execCommand(P_FILL, cmd, 0, page, 0, NULL, 1);
  }

  command void HplAt45db.flush(uint8_t cmd, at45page_t page) {
    execCommand(P_FLUSH, cmd, 0, page, 0, NULL, 1);
  }

  command void HplAt45db.compare(uint8_t cmd, at45page_t page) {
    execCommand(P_COMPARE, cmd, 0, page, 0, NULL, 1);
  }

  command void HplAt45db.erase(uint8_t cmd, at45page_t page) {
    execCommand(P_ERASE, cmd, 0, page, 0, NULL, 1);
  }

  command void HplAt45db.read(uint8_t cmd,
			      at45page_t page, at45pageoffset_t offset,
			      uint8_t *pdata, at45pageoffset_t count) {
    execCommand(P_READ, cmd, 5, page, offset, pdata, count);
  }

  command void HplAt45db.readBuffer(uint8_t cmd, at45pageoffset_t offset,
				    uint8_t *pdata, at45pageoffset_t count) {
    execCommand(P_READ, cmd, 2, 0, offset, pdata, count);
  }

  command void HplAt45db.crc(uint8_t cmd,
			     at45page_t page, at45pageoffset_t offset,
			     at45pageoffset_t count,
			     uint16_t baseCrc) {
    execCommand(P_READ_CRC, cmd, 2, page, offset, (uint8_t *)baseCrc, count);
  }

  command void HplAt45db.write(uint8_t cmd,
			       at45page_t page, at45pageoffset_t offset,
			       uint8_t *pdata, at45pageoffset_t count) {
    execCommand(P_WRITE, cmd, 0, page, offset, pdata, count);
  }
}
