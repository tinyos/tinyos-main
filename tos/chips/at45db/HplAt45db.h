/*
 * Copyright (c) 2005-2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

#ifndef HPLAT45DB_H
#define HPLAT45DB_H

#include "HplAt45db_chip.h"

enum { // commands we're executing (all SPI Mode 0 or 3)
  AT45_C_READ_BUFFER1 = 0xd4,
  AT45_C_READ_BUFFER2 = 0xd6,
  AT45_C_READ_CONTINUOUS = 0xe8,
  AT45_C_READ_PAGE = 0xd2,
  AT45_C_WRITE_BUFFER1 = 0x84,
  AT45_C_WRITE_BUFFER2 = 0x87,
  AT45_C_WRITE_MEM_BUFFER1 = 0x82,
  AT45_C_WRITE_MEM_BUFFER2 = 0x85,
  AT45_C_FILL_BUFFER1 = 0x53, 
  AT45_C_FILL_BUFFER2 = 0x55, 
  AT45_C_FLUSH_BUFFER1 = 0x83,
  AT45_C_FLUSH_BUFFER2 = 0x86,
  AT45_C_QFLUSH_BUFFER1 = 0x88,
  AT45_C_QFLUSH_BUFFER2 = 0x89,
  AT45_C_COMPARE_BUFFER1 = 0x60,
  AT45_C_COMPARE_BUFFER2 = 0x61,
  AT45_C_REQ_STATUS = 0xd7,
  AT45_C_ERASE_PAGE = 0x81,
};


#endif
