/*
 * Copyright (c) 2007 Romain Thouvenin <romain.thouvenin@gmail.com>
 * Published under the terms of the GNU General Public License (GPLv2).
 */

#include "routing.h"

typedef enum block_semantics {
  BLOCK_HEAD = 0x1,
  BLOCK_SEQNUM = 0x2,
  BLOCK_HOPCNT = 0x4
} block_semantics_t;
