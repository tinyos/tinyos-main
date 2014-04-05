#include "lib6lowpan-includes.h"
#include "internal.h"

#define COPY_IEEE154_ADDR(FIELD) \
  if (frame-> FIELD  .ieee_mode == IEEE154_ADDR_SHORT) {         \
    uint16_t tmpval = (frame-> FIELD . i_saddr);                 \
    memcpy(buf, &tmpval, 2);                                     \
    buf += 2;                                                    \
  } else {                                                       \
    memcpy(buf, &(frame-> FIELD .i_laddr), 8);                   \
    buf += 8;                                                    \
  }

uint8_t *pack_ieee154_header(uint8_t *buf, size_t cnt,
                          struct ieee154_frame_addr *frame) {
  uint8_t *ieee_hdr = buf;
  uint16_t fcf;
  // struct ieee154_header_base *ieee_hdr = (struct ieee154_header_base *)buf;
  /* fill in the following 802.15.4 fields: */
  /*    length: will be set once we know how long the data is */
  /*    fcf: (set frame time, addressing modes) */
  /*    destpan: set to address in frame */
  /*    source and destination addresses */

  buf = buf + IEEE154_MIN_HDR_SZ;
  COPY_IEEE154_ADDR(ieee_dst);
  COPY_IEEE154_ADDR(ieee_src);

  fcf = (IEEE154_TYPE_DATA << IEEE154_FCF_FRAME_TYPE);
  fcf |= (frame->ieee_src.ieee_mode << IEEE154_FCF_SRC_ADDR_MODE);
  fcf |= (frame->ieee_dst.ieee_mode << IEEE154_FCF_DEST_ADDR_MODE);
  fcf |= (1 << IEEE154_FCF_INTRAPAN);

  ieee_hdr[1] = (fcf & 0xff);
  ieee_hdr[2] = (fcf >> 8);
  ieee_hdr[4] = frame->ieee_dstpan & 0xff;
  ieee_hdr[5] = frame->ieee_dstpan >> 8;

  return buf;
}

/* Unpack the IEEE154 header from a buffer.
 *
 * Returns 0 on success and -1 if the buffer is too short.
 */
int unpack_ieee154_hdr(uint8_t **buf,
                      size_t *len,
                      struct ieee154_frame_addr *frame) {
  uint16_t fcf;

  if (*len < IEEE154_MIN_HDR_SZ) return -1;

  fcf = ((uint16_t)(*buf)[2] << 8) | (*buf)[1];

  frame->ieee_dstpan = htole16(((uint16_t)(*buf)[5] << 8) | (*buf)[4]);
  frame->ieee_src.ieee_mode = (fcf >> IEEE154_FCF_SRC_ADDR_MODE) & 0x3;
  frame->ieee_dst.ieee_mode = (fcf >> IEEE154_FCF_DEST_ADDR_MODE) & 0x3;

  *buf += IEEE154_MIN_HDR_SZ; *len -= IEEE154_MIN_HDR_SZ;

  if (frame->ieee_dst.ieee_mode == IEEE154_ADDR_SHORT) {
    if (*len < 2) return -1;
    memcpy(&frame->ieee_dst.i_saddr, *buf, 2);
    *buf += 2; *len -= 2;
  } else if (frame->ieee_dst.ieee_mode == IEEE154_ADDR_EXT) {
    if (*len < 8) return -1;
    memcpy(&frame->ieee_dst.i_laddr, *buf, 8);
    *buf += 8; *len -= 8;
  }

  if (frame->ieee_src.ieee_mode == IEEE154_ADDR_SHORT) {
    if (*len < 2) return -1;
    memcpy(&frame->ieee_src.i_saddr, *buf, 2);
    *buf += 2; *len -= 2;
  } else if (frame->ieee_src.ieee_mode == IEEE154_ADDR_EXT) {
    if (*len < 8) return -1;
    memcpy(&frame->ieee_src.i_laddr, *buf, 8);
    *buf += 8; *len -= 8;
  }
  return 0;
}
