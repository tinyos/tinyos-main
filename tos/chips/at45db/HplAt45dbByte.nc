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
 * Interface between generic byte-at-a-time AT45DB HPL implementation and
 * its platform specific aspects.
 * <p>
 * Each platform must provide its own HPL implementation for its AT45DB
 * flash chip. To simplify this task, this directory provides a generic HPL
 * implementation (HplAt45dbByteC) which can easily be used to build an
 * AT45DB HPL by connecting it to a byte-at-a-time SPI interface, and an
 * implementation of the operations of this interface.
 *
 * @author David Gay
 */

interface HplAt45dbByte {
  /**
   * Wait for the flash chip to report that it is idle. This command is
   * called immediately after sending a status request command to the
   * flash, so it is sufficient to wait for the flash's data pin to go
   * high.
   */
  command void waitIdle();
  /**
   * Signaled when the flash chip is idle.
   */
  event void idle();

  /**
   * This command may be called immediately after idle is signaled. It
   * must report the flash's current compare status.
   * @return TRUE if the last compare succeeded, FALSE if it failed.
   */
  command bool getCompareStatus();

  /**
   * Assert the flash's select pin.
   */
  command void select();

  /**
   * Deassert the flash's select pin.
   */
  command void deselect();
}
