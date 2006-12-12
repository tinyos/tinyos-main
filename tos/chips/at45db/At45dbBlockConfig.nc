// $Id: At45dbBlockConfig.nc,v 1.4 2006-12-12 18:23:02 vlahan Exp $

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
 * Private interface between the AT45DB implementations of config and block storage
 *
 * @author: David Gay <dgay@acm.org>
 */

interface At45dbBlockConfig {
  /**
   * Check if this block is a config volumes
   * @return TRUE for config volumes, FALSE for block volumes
   */
  command int isConfig();

  /**
   * Query which half of the block is used by the current config state
   * @return TRUE for 2nd half, FALSE for 1st half
   */
  command int flipped();

  /**
   * Hook called by block storage just before the start of each write
   * @return TRUE to delay the write until <code>writeContinue</code>
   *    is called, FALSE to proceed immediately.
   */
  command int writeHook();
  /**
   * Continue or abort write suspended as a result of a <code>writeHook</code>
   * event
   * @param error SUCCESS to continue write, anything else to abort write 
   *   returning that error code
   */
  event void writeContinue(error_t error);

  /**
   * Return size of a config volume in pages (half of the actual block)
   * @return Config volume size
   */
  event at45page_t npages();

  /**
   * Map a volume-relative page to an absolute flash page, taking account
   * of the current flipped status
   * @param page Volume-relative page
   * @return Actual flash page for <code>page</code>
   */
  event at45page_t remap(at45page_t page);
}
