
/**
 * @author Jeongyeup Paek <jpaek@enl.usc.edu>
 */

#include "DynamicLoader.h"

module NullVolumeMapC
{
  provides interface BlockRead[uint8_t id];
}

implementation
{
  command error_t BlockRead.read[uint8_t id](storage_addr_t addr, void* buf, storage_len_t len) { return FAIL; }
  command error_t BlockRead.computeCrc[uint8_t id](storage_addr_t addr, storage_len_t len, uint16_t crc) { return FAIL; }
  command storage_len_t BlockRead.getSize[uint8_t id]() { return 0; }
}
