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
 * Block storage test application. Does a pattern of random reads and
 * writes, based on mote id. See README.txt for more details.
 *
 * @author David Gay
 */
module RandRWC {
  uses {
    interface Boot;
    interface Leds;
    interface BlockRead;
    interface BlockWrite;
    interface AMSend;
    interface SplitControl as SerialControl;
  }
}
implementation {
  enum {
    SIZE = 1024L * 256,
    NWRITES = SIZE / 4096,
  };

  uint16_t shiftReg;
  uint16_t initSeed;
  uint16_t mask;

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

  void resetSeed() {
    shiftReg = 119 * 119 * ((TOS_NODE_ID % 100) + 1);
    initSeed = shiftReg;
    mask = 137 * 29 * ((TOS_NODE_ID % 100) + 1);
  }
  
  uint8_t data[512], rdata[512];
  int count, testCount;
  uint32_t addr, len;
  uint16_t offset;
  message_t reportmsg;

  void done();

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

  void setParameters() {
    addr = (uint32_t)count << 12 | (rand() >> 6);
    len = rand() >> 7;
    if (addr + len > SIZE)
      addr = SIZE - len;
    offset = rand() >> 8;
    if (offset + len > sizeof data)
      offset = sizeof data - len;
  }

  event void Boot.booted() {
    call SerialControl.start();
  }

  event void SerialControl.stopDone(error_t e) { }

  event void SerialControl.startDone(error_t e) {
    int i;

    if (e != SUCCESS)
      {
	call Leds.led0On();
	return;
      }

    resetSeed();
    for (i = 0; i < sizeof data; i++)
      data[i++] = rand() >> 8;

    done();
  }

  void nextRead() {
    if (++count == NWRITES)
      done();
    else
      {
	setParameters();
	scheck(call BlockRead.read(addr, rdata, len));
      }
  }

  void nextWrite() {
    if (++count == NWRITES)
      {
	call Leds.led2Toggle();
	scheck(call BlockWrite.sync());
      }
    else
      {
	setParameters();
	scheck(call BlockWrite.write(addr, data + offset, len));
      }
  }

  event void BlockWrite.writeDone(storage_addr_t x, void* buf, storage_len_t y, error_t result) {
    if (scheck(result))
      nextWrite();
  }

  event void BlockWrite.eraseDone(error_t result) {
    if (scheck(result))
      {
	call Leds.led2Toggle();
	nextWrite();
      }
  }

  event void BlockWrite.syncDone(error_t result) {
    if (scheck(result))
      done();
  }

  event void BlockRead.readDone(storage_addr_t x, void* buf, storage_len_t rlen, error_t result) __attribute__((noinline)) {
    if (scheck(result) && bcheck(x == addr && rlen == len && buf == rdata &&
				 memcmp(data + offset, rdata, rlen) == 0))
      nextRead();
  }

  event void BlockRead.computeCrcDone(storage_addr_t x, storage_len_t y, uint16_t z, error_t result) {
  }

  enum { A_READ = 2, A_WRITE };

  void doAction(int act) {
    count = 0;
    resetSeed();

    switch (act)
      {
      case A_WRITE:
	scheck(call BlockWrite.erase());
	break;
      case A_READ:
	nextRead();
	break;
      }
  }

  const uint8_t actions[] = {
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

      case A_READ: case A_WRITE:
	if (testCount)
	  success();
	else
	  doAction(act);
	break;

      default:
	fail(FAIL);
	break;
      }
    testCount++;
  }

}
