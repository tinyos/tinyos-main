#ifndef STORAGE_VOLUMES_H
#define STORAGE_VOLUMES_H

#include "Stm25p.h"

#define VOLUME_CATALOG 0
#define VOLUME_DATA 1
  
  /*
   * The M25P16 contains 31 sectors, each sector is 65535 bytes long.
   * This gives 2031585 total bytes.
   */
  static const stm25p_volume_info_t STM25P_VMAP[ 2 ] = 
  {
     { base : 0, size : 1 },  // address 0x00000000 - 0x0000FFFF
     { base : 1, size : 30 }, // address 0x00010000 - 0x001FFFFF
  };
#endif
