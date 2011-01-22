#ifndef _IEEE154_HEADER_H
#define _IEEE154_HEADER_H

uint8_t *pack_ieee154_header(uint8_t *buf, size_t cnt, struct ieee154_frame_addr *frame) ;
uint8_t *unpack_ieee154_hdr(uint8_t *buf, struct ieee154_frame_addr *frame);

#endif
