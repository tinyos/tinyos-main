
#include <stdint.h>
#include <string.h>
#include <stdlib.h>

#include "6lowpan.h"
#include "Ieee154.h"
#include "ip.h"
#include "lib6lowpan.h"
#include "nwbyte.h"
#include "ip_malloc.h"
#include "iovec.h"

int lowpan_frag_get(uint8_t *frag, size_t len,
                    struct ip6_packet *packet,
                    struct ieee154_frame_addr *frame,
                    struct lowpan_ctx *ctx) {
  uint8_t *buf, *lowpan_buf;
  if (ctx->offset > 0)
    return 0;

  /* pack 802.15.4 */
  buf = lowpan_buf = pack_ieee154_header(frag, len, frame);
  
  if (sizeof(struct ip6_hdr) + iov_len(packet->ip6_data) > len - (buf - frag))
    return -1;

  memcpy(buf, &packet->ip6_hdr, sizeof(struct ip6_hdr));
  buf += sizeof(struct ip6_hdr);
  iov_read(packet->ip6_data, 0, iov_len(packet->ip6_data), buf);
  ctx->offset = (buf - frag) + iov_len(packet->ip6_data);
  return ctx->offset;
}

int lowpan_recon_start(struct ieee154_frame_addr *frame_addr,
                       struct lowpan_reconstruct *recon,
                       uint8_t *pkt, size_t len) {
  recon->r_size = len;
  recon->r_buf = malloc(len);
  recon->r_app_len = NULL;
  recon->r_bytes_rcvd = len;
  if (!recon->r_buf)
    return -1;
  memcpy(recon->r_buf, pkt, len);
  return 0;
}
int lowpan_recon_add(struct lowpan_reconstruct *recon,
                     uint8_t *pkt, size_t len) {
  return -1;
}

uint16_t getHeaderBitmap(struct packed_lowmsg *lowmsg) {
  return LOWMSG_NALP + 1;
}

inline uint8_t hasFrag1Header(struct packed_lowmsg *msg) {
  return 0;
}
inline uint8_t hasFragNHeader(struct packed_lowmsg *msg) {
  return 0;
}

inline uint8_t getFragDgramTag(struct packed_lowmsg *msg, uint16_t *tag) {
  return 0;
}

uint8_t *getLowpanPayload(struct packed_lowmsg *lowmsg) {
  return lowmsg->data;
}
