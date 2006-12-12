// $Id: ConfigStorageP.nc,v 1.4 2006-12-12 18:23:02 vlahan Exp $

/*									tab:4
 * Copyright (c) 2002-2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * Private component of the AT45DB implementation of the config storage
 * abstraction.
 *
 * @author: David Gay <dgay@acm.org>
 */

#include "Storage.h"
#include "crc.h"

module ConfigStorageP {
  provides {
    interface Mount[uint8_t id];
    interface ConfigStorage[uint8_t id];
    interface At45dbBlockConfig as BConfig[uint8_t id];
  }
  uses {
    interface At45db;
    interface BlockRead[uint8_t id];
    interface BlockWrite[uint8_t id];
  }
}
implementation 
{
  /* A config storage is built on top of a block storage volume, with
     the block storage volume divided into two and the first 4 bytes of
     each half holding a (>0) version number. The valid half with the
     highest version number is the current version.

     Transactional behaviour is achieved by copying the current half
     into the other, then increment its version number. Writes then
     proceed in that new half until a commit, which just uses the 
     underlying BlockStorage commit's operation.

     Note: all of this depends on the at45db's implementation of 
     BlockStorageP. It will not work over an arbitrary BlockStorageP
     implementation (additionally, it uses hooks in BlockStorageP to
     support the half-volume operation). Additionally, the code assumes
     that the config volumes all have lower ids than the block volumes.
  */

  enum {
    S_STOPPED,
    S_MOUNT,
    S_COMMIT,
    S_CLEAN,
    S_DIRTY,
    S_INVALID
  };

  enum {
    N = uniqueCount(UQ_CONFIG_STORAGE),
    NO_CLIENT = 0xff,
  };

  /* Per-client state. We could keep just the state and current version
     in an array, but this requires more complex arbitration (don't
     release block storage during mount or commit). As I don't expect
     many config volumes, this doesn't seem worth the trouble. */
  struct {
    uint8_t state : 3;
    uint8_t committing : 1;
  } s[N];
  nx_struct {
    nx_uint16_t crc;
    nx_uint32_t version;
  } low[N], high[N];


  /* Bit n is true if client n is using upper block */
  uint8_t flipState[(N + 7) / 8]; 

  uint8_t client = NO_CLIENT;
  at45page_t nextPage;

  void setFlip(uint8_t id, bool flip) {
    if (flip)
      flipState[id >> 3] |= 1 << (id & 7);
    else
      flipState[id >> 3] &= ~(1 << (id & 7));
  }

  bool flipped(uint8_t id) {
    return call BConfig.flipped[id]();
  }

  void flip(uint8_t id) {
    setFlip(id, !flipped(id));
  }

  storage_len_t volumeSize(uint8_t id) {
    return call BlockRead.getSize[id]();
  }

  /* ------------------------------------------------------------------ */
  /* Mounting								*/
  /* ------------------------------------------------------------------ */

  command error_t Mount.mount[uint8_t id]() {
    /* Read version on both halves. Validate higher. Validate lower if
       higher invalid. Use lower if both invalid. */
    if (s[id].state != S_STOPPED)
      return FAIL;

    s[id].state = S_MOUNT;
    setFlip(id, FALSE);
    call BlockRead.read[id](0, &low[id], sizeof low[id]);

    return SUCCESS;
  }

  void computeCrc(uint8_t id) {
    call BlockRead.computeCrc[id](sizeof(nx_uint16_t),
				  volumeSize(id) - sizeof(nx_uint16_t),
				  0);
  }

  void mountReadDone(uint8_t id, error_t error) {
    if (error != SUCCESS)
      {
	s[id].state = S_STOPPED;
	signal Mount.mountDone[id](FAIL);
      }
    else if (!call BConfig.flipped[id]())
      {
	/* Just read low-half version. Read high-half version */
	setFlip(id, TRUE);
	call BlockRead.read[id](0, &high[id], sizeof high[id]);
      }
    else
      {
	/* Verify the half with the largest version */
	setFlip(id, high[id].version > low[id].version);
	computeCrc(id);
      }
  }

  void mountCrcDone(uint8_t id, uint16_t crc, error_t error) {
    bool isflipped = call BConfig.flipped[id]();

    if (error == SUCCESS &&
	crc == (isflipped ? high[id].crc : low[id].crc))
      {
	/* We just use the low data once mounted */
	if (isflipped)
	  low[id].version = high[id].version;
	s[id].state = S_CLEAN;
      }
    else
      {
	// try the other half?
	if ((high[id].version > low[id].version) == isflipped)
	  {
	    /* Verification of the half with the highest version failed. Try
	       the other half. */
	    setFlip(id, !isflipped);
	    computeCrc(id);
	    return;
	  }
	/* Both halves bad, terminate. Reads will fail. */
	s[id].state = S_INVALID;
	low[id].version = 0;
      }
    signal Mount.mountDone[id](SUCCESS);
  }

  /* ------------------------------------------------------------------ */
  /* Read								*/
  /* ------------------------------------------------------------------ */

  command error_t ConfigStorage.read[uint8_t id](storage_addr_t addr, void* buf, storage_len_t len) {
    /* Read from current half using BlockRead */
    if (s[id].state < S_CLEAN)
      return EOFF;
    if (s[id].state == S_INVALID) // nothing to read
      return FAIL;

    return call BlockRead.read[id](addr + sizeof low[0], buf, len);
  }

  void readReadDone(uint8_t id, storage_addr_t addr, void* buf, storage_len_t len, error_t error) {
    signal ConfigStorage.readDone[id](addr - sizeof low[0], buf, len, error);
  }

  /* ------------------------------------------------------------------ */
  /* Write								*/
  /* ------------------------------------------------------------------ */

  command error_t ConfigStorage.write[uint8_t id](storage_addr_t addr, void* buf, storage_len_t len) {
    /* 1: If first write:
         copy to other half with incremented version number
       2: Write to other half using BlockWrite */

    if (s[id].state < S_CLEAN)
      return EOFF;
    return call BlockWrite.write[id](addr + sizeof low[0], buf, len);
  }

  void copyCopyPageDone(error_t error);
  void writeContinue(error_t error);

  command int BConfig.writeHook[uint8_t id]() {
    if (s[id].committing)
      return FALSE;

    flip(id); /* We write to the non-current half... */
    if (s[id].state != S_CLEAN) // no copy if dirty or invalid
      return FALSE;

    /* Time to do the copy dance */
    client = id;
    nextPage = signal BConfig.npages[id]();
    copyCopyPageDone(SUCCESS);

    return TRUE;
  }

  void copyCopyPageDone(error_t error) {
    if (error != SUCCESS)
      writeContinue(error);
    else if (nextPage == 0) // copy done
      {
	s[client].state = S_DIRTY;
	writeContinue(SUCCESS);
      }
    else
      {
	// copy next page
	at45page_t from, to, npages = signal BConfig.npages[client]();

	to = from = signal BConfig.remap[client](--nextPage);
	if (flipped(client))
	  from -= npages;
	else
	  from += npages;

	call At45db.copyPage(from, to);
      }
  }

  void writeContinue(error_t error) {
    uint8_t id = client;

    client = NO_CLIENT;
    signal BConfig.writeContinue[id](error);
  }

  void writeWriteDone(uint8_t id, storage_addr_t addr, void* buf, storage_len_t len, error_t error) {
    flip(id); // flip back to current half
    signal ConfigStorage.writeDone[id](addr - sizeof low[0], buf, len, error);
  }

  /* ------------------------------------------------------------------ */
  /* Commit								*/
  /* ------------------------------------------------------------------ */

  void commitSyncDone(uint8_t id, error_t error);

  command error_t ConfigStorage.commit[uint8_t id]() {
    error_t ok;
    uint16_t crc;
    uint8_t i;

    if (s[id].state < S_CLEAN)
      return EOFF;

    if (s[id].state == S_CLEAN)
      /* A dummy CRC call to avoid signaling a completion event from here */
      return call BlockRead.computeCrc[id](0, 1, 0);

    /* Compute CRC for new version and current contents */
    flip(id);
    low[id].version++;
    for (crc = 0, i = 0; i < sizeof low[id].version; i++)
      crc = crcByte(crc, ((uint8_t *)&low[id] + sizeof(nx_uint16_t))[i]);
    ok = call BlockRead.computeCrc[id](sizeof low[id],
				       volumeSize(id) - sizeof low[id],
				       crc);
    if (ok == SUCCESS)
      s[id].committing = TRUE;

    return ok;
  }

  void commitCrcDone(uint8_t id, uint16_t crc, error_t error) {
    /* Weird commit of clean volume hack: we just complete now, w/o
       really doing anything. Ideally we should short-circuit out in the
       commit call, but that would break the "no-signal-from-command"
       rule. So we just waste the CRC computation effort instead - the
       assumption is people don't regularly commit clean volumes. */
    if (s[id].state == S_CLEAN)
      signal ConfigStorage.commitDone[id](error);
    else if (error != SUCCESS)
      commitSyncDone(id, error);
    else
      {
	low[id].crc = crc;
	call BlockWrite.write[id](0, &low[id], sizeof low[id]);
      }
  }

  void commitWriteDone(uint8_t id, error_t error) {
    if (error != SUCCESS)
      commitSyncDone(id, error);
    else
      call BlockWrite.sync[id]();
  }

  void commitSyncDone(uint8_t id, error_t error) {
    s[id].committing = FALSE;
    if (error == SUCCESS)
      s[id].state = S_CLEAN;
    else
      flip(id); // revert to old block
    signal ConfigStorage.commitDone[id](error);
  }

  /* ------------------------------------------------------------------ */
  /* Get Size								*/
  /* ------------------------------------------------------------------ */

  command storage_len_t ConfigStorage.getSize[uint8_t id]() {
    return volumeSize(id) - sizeof low[0];
  }

  /* ------------------------------------------------------------------ */
  /* Valid								*/
  /* ------------------------------------------------------------------ */

  command bool ConfigStorage.valid[uint8_t id]() {
    return s[id].state != S_INVALID;
  }

  /* ------------------------------------------------------------------ */
  /* Interface with BlockStorageP					*/
  /* ------------------------------------------------------------------ */

  /* The config volumes use the low block volume numbers. So a volume is a
     config volume iff its its id is less than N */

  command int BConfig.isConfig[uint8_t id]() {
    return id < N;
  }

  inline command int BConfig.flipped[uint8_t id]() {
    return (flipState[id >> 3] & (1 << (id & 7))) != 0;
  }

  event void BlockRead.readDone[uint8_t id](storage_addr_t addr, void* buf, storage_len_t len, error_t error) {
    if (id < N)
      if (s[id].state == S_MOUNT)
	mountReadDone(id, error);
      else
	readReadDone(id, addr, buf, len, error);
  }

  event void BlockWrite.writeDone[uint8_t id]( storage_addr_t addr, void* buf, storage_len_t len, error_t error ) {
    if (id < N)
      if (s[id].committing)
	commitWriteDone(id, error);
      else
	writeWriteDone(id, addr, buf, len, error);
  }

  event void BlockWrite.syncDone[uint8_t id]( error_t error ) {
    if (id < N)
      commitSyncDone(id, error);
  }

  event void BlockRead.computeCrcDone[uint8_t id]( storage_addr_t addr, storage_len_t len, uint16_t crc, error_t error ) {
    if (id < N)
      if (s[id].state == S_MOUNT)
	mountCrcDone(id, crc, error);
      else
	commitCrcDone(id, crc, error);
  }

  event void At45db.copyPageDone(error_t error) {
    if (client != NO_CLIENT)
      copyCopyPageDone(error);
  }

  event void BlockWrite.eraseDone[uint8_t id](error_t error) {}
  event void At45db.eraseDone(error_t error) {}
  event void At45db.syncDone(error_t error) {}
  event void At45db.flushDone(error_t error) {}
  event void At45db.readDone(error_t error) {}
  event void At45db.computeCrcDone(error_t error, uint16_t crc) {}
  event void At45db.writeDone(error_t error) {}

  default event void Mount.mountDone[uint8_t id](error_t error) { }
  default event void ConfigStorage.readDone[uint8_t id](storage_addr_t addr, void* buf, storage_len_t len, error_t error) {}
  default event void ConfigStorage.writeDone[uint8_t id](storage_addr_t addr, void* buf, storage_len_t len, error_t error) {}
  default event void ConfigStorage.commitDone[uint8_t id](error_t error) {}
}
