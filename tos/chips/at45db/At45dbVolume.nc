/*
 * Copyright (c) 2005-2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

#include "At45db.h"

/**
 * AT45DB interface for managing flash volumes.
 *
 * @author David Gay
 */
interface At45dbVolume {
  /**
   * Map a volume page to the corresponding page in the whole flash
   * @return What flash page this volume page maps to, or 
   *   AT45_MAX_PAGES for invalid volumes
   */
  command at45page_t remap(at45page_t volumePage);

  /**
   * Find the flash volume size
   * @return Flash volume size in pages
   */
  command at45page_t volumeSize();
}
