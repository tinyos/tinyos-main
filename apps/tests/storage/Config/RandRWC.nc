/* $Id: RandRWC.nc,v 1.3 2006-11-07 19:30:37 scipio Exp $
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Config storage test application. Does a pattern of random reads and
 * writes, based on mote id. See README.txt for more details.
 *
 * @author David Gay
 */
module RandRWC {
  uses {
    interface Boot;
    interface Leds;
    interface ConfigStorage;
    interface AMSend;
    interface SplitControl as SerialControl;
    interface Mount as ConfigMount;
  }
}
implementation {
  enum {
    SIZE = 2048,
    NWRITES = 100,
  };

  uint16_t shiftReg;
  uint16_t initSeed;
  uint16_t mask;

  uint8_t data[512], rdata[512];
  int count, testCount, writeCount, countAtCommit;
  struct {
    uint32_t addr;
    void *data;
    uint16_t len;
  } ops[NWRITES];

  message_t reportmsg;


  void done();

  /* Return the next 16 bit random number */
  uint16_t rand() {
    bool endbit;
    uint16_t tmpShiftReg;

    tmpShiftReg = shiftReg;
    endbit = ((tmpShiftReg & 0x8000) != 0);
    tmpShiftReg <<= 1;
    if (endbit) 
      tmpShiftReg ^= 0x100b;
    tmpShiftReg++;
    shiftReg = tmpShiftReg;
    tmpShiftReg = tmpShiftReg ^ mask;

    return tmpShiftReg;
  }

  void resetSeed(int offset) {
    shiftReg = 119 * 119 * ((TOS_NODE_ID % 100) + 1 + offset);
    initSeed = shiftReg;
    mask = 137 * 29 * ((TOS_NODE_ID % 100) + 1 + offset);
  }
  
  void report(error_t e) {
    uint8_t *msg = call AMSend.getPayload(&reportmsg);

    msg[0] = e;
    if (call AMSend.send(AM_BROADCAST_ADDR, &reportmsg, 1) != SUCCESS)
      call Leds.led0On();
  }

  event void AMSend.sendDone(message_t* msg, error_t error) {
    if (error != SUCCESS)
      call Leds.led0On();
  }

  void fail(error_t e) {
    call Leds.led0On();
    report(e);
  }

  void success() {
    call Leds.led1On();
    report(0x80);
  }

  bool scheck(error_t r) __attribute__((noinline)) {
    if (r != SUCCESS)
      fail(r);
    return r == SUCCESS;
  }

  bool bcheck(bool b) {
    if (!b)
      fail(FAIL);
    return b;
  }

  void setupOps(int wcount) {
    int i;
    uint16_t offset;

    count = 0;
    resetSeed(wcount);

    for (i = 0; i < NWRITES; i++)
      {
	uint16_t addr = rand() & (SIZE - 1);
	uint16_t len = rand() >> 7;
	if (addr + len > SIZE)
	  addr = SIZE - len;
	ops[i].addr = addr;
	ops[i].len = len;
	offset = rand() >> 8;
	if (offset + ops[i].len > sizeof data)
	  offset = sizeof data - ops[i].len;
	ops[i].data = data + offset;
      }
  }

  int overlap(int a, int b) {

    return ops[a].addr >= ops[b].addr && ops[a].addr < ops[b].addr + ops[b].len;
  }

  int overwritten(int c) {
    int i;

    /* True if write c is overwritten by a later write */
    for (i = c + 1; i < NWRITES; i++)
      if (overlap(i, c) || overlap(c, i))
	return TRUE;
    return FALSE;
  }

  void nextRead() {
    int c = count++;

    if (c == NWRITES)
      done();
    else
      scheck(call ConfigStorage.read(ops[c].addr, rdata, ops[c].len));
  }

  event void ConfigStorage.readDone(storage_addr_t x, void* buf, storage_len_t rlen, error_t result) __attribute__((noinline)) {
    int c = count - 1;

    if (scheck(result) &&
	bcheck(x == ops[c].addr && rlen == ops[c].len && buf == rdata) &&
	bcheck(overwritten(c) || memcmp(ops[c].data, rdata, rlen) == 0))
      nextRead();
  }

  void nextWrite() {
    int c = count++;

    if (c == NWRITES)
      done();
    else
      scheck(call ConfigStorage.write(ops[c].addr, ops[c].data, ops[c].len));
  }

  event void ConfigStorage.writeDone(storage_addr_t x, void *buf, storage_len_t y, error_t result) {
    int c = count - 1;

    if (scheck(result) &&
	bcheck(x == ops[c].addr && y == ops[c].len && buf == ops[c].data))
      nextWrite();
  }

  event void ConfigStorage.commitDone(error_t result) {
    if (scheck(result))
      done();
  }

  event void Boot.booted() {
    int i;

    resetSeed(0);
    for (i = 0; i < sizeof data; i++)
      data[i++] = rand() >> 8;

    call SerialControl.start();
  }

  event void SerialControl.startDone(error_t e) {
    if (e != SUCCESS)
      {
	call Leds.led0On();
	return;
      }

    scheck(call ConfigMount.mount());
  }

  event void ConfigMount.mountDone(error_t e) {
    if (e != SUCCESS)
      fail(e);
    else
      done();
  }

  enum { A_COMMIT, A_READ, A_WRITE };

  void doAction(int act) {
    switch (act)
      {
      case A_COMMIT:
	countAtCommit = writeCount;
	scheck(call ConfigStorage.commit());
	break;
      case A_WRITE:
	setupOps(++writeCount);
	nextWrite();
	break;
      case A_READ:
	setupOps(countAtCommit);
	nextRead();
	break;
      }
  }

  const uint8_t actions[] = {
    A_WRITE,
    A_COMMIT,
    A_READ,
    A_WRITE,
    A_COMMIT,
    A_READ,
    A_WRITE,
    A_READ
  };

  void done() {
    uint8_t act = TOS_NODE_ID / 100;

    call Leds.led2Toggle();

    switch (act)
      {
      case 0:
	if (testCount < sizeof actions)
	  doAction(actions[testCount]);
	else
	  success();
	break;

      default:
	if (testCount)
	  success();
	else
	  {
	    uint8_t i, nwrites = 0;

	    /* Figure out countAtCommit */
	    for (i = 0; i < sizeof actions; i++)
	      switch (actions[i])
		{
		case A_WRITE:
		  nwrites++;
		  break;
		case A_COMMIT:
		  countAtCommit = nwrites;
		  break;
		}

	    /* And check we have the right data */
	    doAction(A_READ);
	  }
	break;
      }
    testCount++;
  }

  event void SerialControl.stopDone(error_t e) { }
}
