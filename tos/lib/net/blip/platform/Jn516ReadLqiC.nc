/**
 * Dummy component for BLIP.
 *
 * @author Tim Bormann <code@tkn.tu-berlin.de>
 */

module Jn516ReadLqiC {
  provides interface ReadLqi;
} implementation {
  command uint8_t ReadLqi.readLqi(message_t *msg) {
    return 0xFF;
  }

  command uint8_t ReadLqi.readRssi(message_t *msg) {
    return 0xFF;
  }
}

