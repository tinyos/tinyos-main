/*
 * "Copyright (c) 2008 The Regents of the University  of California.
 * All rights reserved."
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
/*
 * Copyright (c) 2007 Matus Harvan
 * All rights reserved
 *
 * Copyright (c) 2008 Stephen Dawson-Haggerty
 * Extensivly modified to use lib6lowpan / b6lowpan.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * The name of the author may not be used to endorse or promote
 *       products derived from this software without specific prior
 *       written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <time.h>
#include <stdarg.h>
#include <termios.h>
#include <errno.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/stat.h>

#include "TrackFlows.h"

#include "tun_dev.h"
#include "serialsource.h"
#include "serialpacket.h"
#include "serialprotocol.h"
#include "sfsource.h"

#include "6lowpan.h"
#include "ip.h"
#include "lib6lowpan.h"
#include "IEEE154.h"
#include "routing.h"
#include "devconf.h"
#include "logging.h"
#include "config.h"
#include "nwstate.h"
#include "vty.h"

#define min(a,b) ( (a>b) ? b : a )
#define max(a,b) ( (a>b) ? a : b )

int tun_fd, radvd_fd = -1, fifo_fd = -1, keepalive_needed = 1;
int opt_listenonly = 0, opt_trackflows = 0;

int radvd_init(char *ifname, struct config *c);
void radvd_process();

#ifndef SF_SRC
serial_source ser_src;
#define write_pan_packet(DATA, LEN) write_serial_packet(ser_src, DATA, LEN)
#define read_pan_packet(LENP) read_serial_packet(ser_src, LENP)
#define close_pan()   close_serial_source(ser_src);
#else
int sf_fd;
#define write_pan_packet(DATA, LEN) write_sf_packet(sf_fd, DATA, LEN)
#define read_pan_packet(LENP) read_sf_packet(sf_fd, LENP)
#define close_pan()           close(sf_fd)
#endif

sig_atomic_t do_shutdown = 0;

void driver_shutdown() {
  do_shutdown = 1;
}


enum {
  N_RECONSTRUCTIONS = 10,
};

/*
 */ 
#ifdef __TARGET_mips__
const char *def_configfile = "/etc/lowpan/serial_tun.conf";
#else
const char *def_configfile = "serial_tun.conf";
#endif



extern struct in6_addr __my_address;
uint16_t local_seqno = 0;

volatile sig_atomic_t config_success = 0;
struct config driver_config;
char dev[IFNAMSIZ];
struct {
  time_t boot_time;
  unsigned long tx_pkts;
  unsigned long tx_frags;
  unsigned long tx_bytes;
  unsigned long rx_pkts;
  unsigned long rx_frags;
  unsigned long rx_bytes;
  unsigned long fw_pkts;
} stats = {0, 0, 0, 0, 0, 0, 0, 0};

#ifdef CENTRALIZED_ROUTING
void install_route(struct split_ip_msg *amsg, uint8_t flags);
void uninstall_route(uint16_t n1, uint16_t n2);
#endif


/* ------------------------------------------------------------------------- */

void stderr_msg(serial_source_msg problem)
{
  // fprintf(stderr, "Note: %s\n", msgs[problem]);
}


void print_ip_packet(struct split_ip_msg *msg) {
  int i;
  struct generic_header *g_hdr;
  if (log_getlevel() > LOGLVL_DEBUG) return;

  printf("  nxthdr: 0x%x hlim: 0x%x\n", msg->hdr.nxt_hdr, msg->hdr.hlim);
  printf("  src: ");
  for (i = 0; i < 16; i++) printf("0x%x ", msg->hdr.ip6_src.s6_addr[i]);
  printf("\n");
  printf("  dst: ");
  for (i = 0; i < 16; i++) printf("0x%x ", msg->hdr.ip6_dst.s6_addr[i]);
  printf("\n");

  g_hdr = msg->headers;
  while (g_hdr != NULL) {
    printf("header [%i]: ", g_hdr->len);
    for (i = 0; i < g_hdr->len; i++)
      printf("0x%x ", g_hdr->hdr.data[i]);
    printf("\n");
    g_hdr = g_hdr->next;
  }

  printf("data [%i]:\n\t", msg->data_len);
  for (i = 0; i < msg->data_len; i++) {
    if (i == 0x40) {
      printf (" ...\n");
      break;
    }
    printf("0x%x ", msg->data[i]);
    if (i % 16 == 15) printf("\n\t");
    if (i % 16 == 7) printf ("  ");
  }
  printf("\n");
}


const char *fifo_name = "/var/run/ip-driver/flows";
void fifo_open() {
  struct stat stat_buf;

  if (opt_trackflows) {
    if (stat(fifo_name, &stat_buf) < 0) {
      error("fifo does not exist -- track flows will be diabled\n");
      return;
    }
    fifo_fd = open(fifo_name, O_WRONLY | O_NONBLOCK );
    if (fifo_fd < 0) {
      error("unable to open fifo %i %s: is a reader connected?\n", fifo_fd, fifo_name);
      fifo_fd = -1;
      return;
    }
  }
}
void fifo_close() {
  if (fifo_fd >= 0) {
    close(fifo_fd);
  }
}

enum { N_OUTGOING_CACHE = 10, }; int outgoing_cache_idx = 0;
struct flow_id_msg outgoing_cache[N_OUTGOING_CACHE];

void fifo_report(struct split_ip_msg *msg, uint16_t dest, int nxt_hdr) {
  if (fifo_fd >= 0) {
    outgoing_cache_idx = (outgoing_cache_idx + 1) % N_OUTGOING_CACHE;
    outgoing_cache[outgoing_cache_idx].flow = msg->flow_id;
    outgoing_cache[outgoing_cache_idx].src  = ntohs(msg->hdr.ip6_src.s6_addr16[7]);
    outgoing_cache[outgoing_cache_idx].dst  = ntohs(msg->hdr.ip6_dst.s6_addr16[7]);
    outgoing_cache[outgoing_cache_idx].local_address = ntohs(__my_address.s6_addr16[7]);
    outgoing_cache[outgoing_cache_idx].nxt_hdr = nxt_hdr;
    outgoing_cache[outgoing_cache_idx].n_attempts = 1;
    outgoing_cache[outgoing_cache_idx].attempts[0].next_hop = (dest);
    debug("adding cache entry: %i %i\n",  outgoing_cache[outgoing_cache_idx].src,
          outgoing_cache[outgoing_cache_idx].flow);
  }
}

void flow_insert_label(struct split_ip_msg *msg) {
  uint8_t *buf;
  struct generic_header *g_hdr;


  if (opt_trackflows) {
    buf = malloc(sizeof(struct ip6_ext) + sizeof(struct tlv_hdr) + sizeof(struct flow_id));
    g_hdr = (struct generic_header *)malloc(sizeof(struct generic_header));
    struct ip6_ext *ext = (struct ip6_ext *)buf;
    struct tlv_hdr *tlv = (struct tlv_hdr *)(ext + 1);
    struct flow_id *id  = (struct flow_id *)(tlv + 1);

    ext->nxt_hdr = msg->hdr.nxt_hdr;
    msg->hdr.nxt_hdr = IPV6_HOP;
    ext->len = sizeof(struct ip6_ext) + sizeof(struct tlv_hdr) + sizeof(struct flow_id);
    tlv->type = TLV_TYPE_FLOW;
    tlv->len = ext->len - sizeof(struct ip6_ext);
    id->id = msg->flow_id;
  
    g_hdr->payload_malloced = 1;
    g_hdr->hdr.ext = ext;
    g_hdr->len = ext->len;
    g_hdr->next = msg->headers;
    msg->headers = g_hdr;
    
    msg->hdr.plen = htons(ntohs(msg->hdr.plen) + ext->len);
  }
}

/*
 * frees the linked list structs, and their payloads if we have
 * malloc'ed them at some other point.
 *
 * does not free the payload buffer or the actual split_ip_msg struct,
 * since those are malloc'ed seperatly in this implementation.
 */
void free_split_msg(struct split_ip_msg *msg) {
  struct generic_header *cur, *next;
  cur = msg->headers;
  while (cur != NULL) {
    next = cur->next;
    if (cur->payload_malloced)
      free(cur->hdr.data);
    free(cur);
    cur = next;
  }
}

void configure_timeout() {
  if (config_success == 0) {
    fatal("configuring interface failed!  aborting!\n");
    exit(2);
  } else {
    signal(SIGALRM, SIG_DFL);
  }
}

void configure_reboot() {
  uint8_t buf[sizeof(config_cmd_t) + 1];
  config_cmd_t *cmd = (config_cmd_t *)(&buf[1]);
  memset(buf, 0, sizeof(config_cmd_t) + 1);
  buf[0] = TOS_SERIAL_DEVCONF;
  cmd->cmd = CONFIG_REBOOT;

  signal(SIGALRM, configure_timeout);
  write_pan_packet(buf, CONFIGURE_MSG_SIZE + 1);
  alarm(5);
}

void configure_setparms(struct config *c, int cmdno) {
  uint8_t buf[sizeof(config_cmd_t) + 1];
  config_cmd_t *cmd = (config_cmd_t *)(&buf[1]);
  memset(buf, 0, sizeof(config_cmd_t) + 1);
  buf[0] = TOS_SERIAL_DEVCONF;
  cmd->cmd = cmdno;
  cmd->rf.addr = c->router_addr.s6_addr16[7]; // is network byte-order
  cmd->rf.channel = c->channel;
  cmd->retx.retries = htons(c->retries);
  cmd->retx.delay = htons(30);

  write_pan_packet(buf, CONFIGURE_MSG_SIZE + 1);
}


/* ------------------------------------------------------------------------- */
/*
 * the first byte the TOS serial stack sends is a dispatch byte.  One
 * dispatch value is for forwarded 802;.15.4 packets; we use a few
 * others to talk directly to the attached IPBaseStation.
 */
void handle_other_pkt(uint8_t *data, int len) {
  config_reply_t *rep;
  switch (data[0]) {
  case TOS_SERIAL_DEVCONF:
    rep = (config_reply_t *)(&data[1]);
    debug("interface configured (0x%x) addr: 0x%x\n", rep->error, ntohs(rep->addr));
    switch (rep->error) {
    case CONFIG_ERROR_BOOTED:
      configure_setparms(&driver_config, CONFIG_SET_PARM);
      break;
    default:
      info("interface device successfully initialized\n");
      config_success = 1;

      /* put this here because we already use SIGALRM for the
         configure timeout, and radvd needs it for its own timer. */
      if (radvd_fd < 0 && (radvd_fd = radvd_init(dev, &driver_config)) < 0) {
        fatal("radvd init failed!\n");
        exit(1);
      } 
    }
    break;
  default:
    warn("received serial packet with unknown dispatch 0x%x\n",data[0]);
    log_dump_serial_packet(data, len);
  }
}


/* ------------------------------------------------------------------------- */
/* handling of data arriving on the tun interface */
void write_radio_header(uint8_t *serial, ieee154_saddr_t dest, uint16_t payload_len) {
  IEEE154_header_t *radioPacket = (IEEE154_header_t *)(serial + 1);
  radioPacket->length = payload_len + MAC_HEADER_SIZE + MAC_FOOTER_SIZE;

  // don't include the length byte
  radioPacket->fcf = htons(0x4188);
  // dsn will get set on mote
  radioPacket->destpan = 0;
  radioPacket->dest = htole16(dest);
  // src will get set on mote 
  
  serial[0] = SERIAL_TOS_SERIAL_802_15_4_ID;
}

void send_fragments (struct split_ip_msg *msg, ieee154_saddr_t dest) {
  int result;
  uint16_t frag_len;
  fragment_t progress;
  uint8_t serial[LOWPAN_LINK_MTU + 1];
  IEEE154_header_t *radioPacket = (IEEE154_header_t *)(serial + 1);
#define PKTLEN(X) ((X)->length + 2)

  uint8_t *lowpan = (uint8_t *)(radioPacket + 1);

#define LOWPAN_PAYLOAD_LENGTH (LOWPAN_LINK_MTU - MAC_HEADER_SIZE \
                              - MAC_FOOTER_SIZE)

  progress.offset = 0;

  // and IEEE 802.15.4 header
  // write_radio_header(serial, dest, frag_len);

  while ((frag_len = getNextFrag(msg, &progress, lowpan, 
                                 LOWPAN_PAYLOAD_LENGTH)) > 0) {

    //debug("frag len: 0x%x offset: 0x%x plen: 0x%x\n", frag_len, progress.offset * 8, ntohs(ip_header->plen));

    write_radio_header(serial, dest, frag_len);

    // if this is sent too fast, the base station can't keep up.  The effect of this is
    // we send incomplete fragment.  25ms seems to work pretty well.
    // usleep(30000);
    //   6-9-08 : SDH : this is a bad fix that does not address the
    //   problem.  
    //   at the very least, the serial ack's seem to be
    //   working, so we should be retrying if the ack is failing
    //   because the hardware cannot keep up.
#ifdef __TARGET_mips__
    usleep(50000);
#endif

    log_dump_serial_packet(serial, PKTLEN(radioPacket));
    result = write_pan_packet(serial, PKTLEN(radioPacket));
    if (result != 0)
      result = write_pan_packet(serial, PKTLEN(radioPacket));

    debug("send_fragments: result: 0x%x len: 0x%x\n", result, frag_len);
    log_dump_serial_packet(serial, PKTLEN(radioPacket));
    stats.tx_frags++;
    stats.tx_bytes += PKTLEN(radioPacket);
  }
  keepalive_needed = 0;
  stats.tx_pkts++;
}

void icmp_unreachable(struct split_ip_msg *msg) {
  
}

/*
 * this function takes a complete IP packet, and sends it out to a
 * destination in the PAN.  It will insert source routing headers and
 * recompute L4 checksums as necessary.
 *
 */ 
uint8_t ip_to_pan(struct split_ip_msg *msg) {
  int nxt_hdr = msg->hdr.nxt_hdr;
  uint16_t dest;

  debug("ip_to_pan\n");
  print_ip_packet(msg);
  // if this packet has a source route (rinstall header, or prexisting
  // source header, we don't want to mess with it
  switch (routing_is_onehop(msg)) {
  case ROUTE_MHOP:
    debug("Multihop packet\n");
    if (routing_insert_route(msg)) goto fail;
    break;
    
  case ROUTE_WORMHOLE:
    debug("Wormhole packet\n");

    // fall through
  case ROUTE_NO_ROUTE:
    tun_write(tun_fd, msg);
    // info("destination unreachable: 0x%x: dropping\n", ntohs(msg->hdr.ip6_dst.s6_addr16[7]));
    return 0;
  }

  dest = routing_get_nexthop(msg);
  debug("next hop: 0x%x\n", dest);
  flow_insert_label(msg);
  print_ip_packet(msg);

  fifo_report(msg, dest, nxt_hdr);

  send_fragments(msg, dest);
  return 0;
 fail:
  error("ip_to_pan: no route to host\n");
  return 1;
}

void upd_source_route(struct ip6_route *sh, ieee154_saddr_t addr) {
  if (sh->segs_remain > 0) {
    sh->hops[ROUTE_NENTRIES(sh) - sh->segs_remain] = leton16(addr);
    sh->segs_remain--;
  }
}

int process_dest_tlv(struct ip6_hdr *iph, struct ip6_ext *hdr, int len) {
  struct tlv_hdr *tlv = (struct tlv_hdr *)(hdr + 1);
  node_id_t reporter = ntohs(iph->ip6_src.s6_addr16[7]);

  if (len != hdr-> len) return 1;
  len -= sizeof(struct ip6_ext);

  while (tlv != NULL && len > 0) {
    if (tlv->len == 0) return 1;

    switch(tlv->type) {
    case TLV_TYPE_TOPOLOGY:
      routing_add_report(reporter, tlv);
      break;
    }
    
    len -= tlv->len;
    tlv = (struct tlv_hdr *)(((uint8_t *)tlv) + tlv->len);
  }
  return 0;
}

int process_hop_tlv(struct split_ip_msg *msg, struct ip6_ext *hdr, int len) {
  struct tlv_hdr *tlv = (struct tlv_hdr *)(hdr + 1);
  uint16_t *fl;

  if (len != hdr-> len) return 1;
  len -= sizeof(struct ip6_ext);

  while (tlv != NULL && len > 0) {
    if (tlv->len == 0) return 1;

    switch(tlv->type) {
    case TLV_TYPE_FLOW:
      fl = (uint16_t *)(tlv + 1);
      msg->flow_id = *fl;
      debug("process_hop_tlv: flow 0x%x\n", msg->flow_id);
      break;
    }

    len -= tlv->len;
    tlv = (struct tlv_hdr *)(((uint8_t *)tlv) + tlv->len);
  }
  return 0;
}

int process_extensions(struct split_ip_msg *msg) {
  struct generic_header *prev = NULL, *cur = msg->headers;
  struct ip6_route *route;
  uint8_t nxt_hdr = msg->hdr.nxt_hdr;
  int lendelta = 0;

  while (cur != NULL && EXTENSION_HEADER(nxt_hdr)) {
    debug("dropping header type 0x%x, len %i\n", nxt_hdr, cur->len);
    msg->headers = cur->next;
    msg->hdr.nxt_hdr = cur->hdr.ext->nxt_hdr;
    lendelta += cur->len;

    switch (nxt_hdr) {
    case IPV6_DEST:
      if (process_dest_tlv(&msg->hdr, cur->hdr.ext, cur->len)) 
        return 1;
      break;
    case IPV6_HOP:
      if (process_hop_tlv(msg, cur->hdr.ext, cur->len)) {
        warn("dropping packet due to hop tlv\n");
        return 1;
      }
      break;
    case IPV6_ROUTING:

      route = cur->hdr.sh;

      if ((route->type & ~IP6ROUTE_FLAG_MASK) == IP6ROUTE_TYPE_INVAL || route->segs_remain == 0) {
/*         if (route->type == IP6ROUTE_TYPE_INVAL) { */
/*           if (route->hops[0] == __my_address.s6_addr16[7]) { */
/*             warn("dropping packet since it has an invalid source route and I sent it\n"); */
/*             return 1; */
/*           } */
/*         } */
      } else {
        uint16_t target_hop = ntohs(route->hops[ROUTE_NENTRIES(route) - route->segs_remain]);
        // if this is actually a valid source route, maybe update it
        // (even though we're going to delete it shortly)
        if (target_hop != __my_address.s6_addr16[7]) {
          if (ROUTE_NENTRIES(route) >= 2) {
            route->hops[0] = htons(msg->prev_hop);
            route->hops[1] = htons(target_hop);
          }
          route->type = (route->type & IP6ROUTE_FLAG_MASK) | IP6ROUTE_TYPE_INVAL;
        } else {
          route->hops[ROUTE_NENTRIES(route) - route->segs_remain] = htons(msg->prev_hop);
          route->segs_remain--;
        }
      }
      
      if ((route->type & ~IP6ROUTE_FLAG_MASK) == IP6ROUTE_TYPE_INVAL && ROUTE_NENTRIES(route) >= 2) {
        node_id_t n1 = ntohs(route->hops[0]);
        node_id_t n2 = ntohs(route->hops[1]);
        warn ("broken link was %i -> %i\n", n1, n2);
        nw_remove_link(n1, n2);
        if (route->type & IP6ROUTE_FLAG_CONTROLLER) {
          warn("dropping packet since it has an invalid source route and I sent it\n");
          return 1;
        } else {
          warn("received broken source route based on installed route-- uninstalling\n");
/*           uninstall_route(ntohs(msg->hdr.ip6_src.s6_addr16[7]), */
/*                           ntohs(msg->hdr.ip6_dst.s6_addr16[7])); */
        }
      }
    }

    nxt_hdr = cur->hdr.ext->nxt_hdr;
    prev = cur;
    cur = cur->next;
    free(prev);
  }

  msg->hdr.plen = htons(ntohs(msg->hdr.plen) - lendelta);
  return 0;
}

#if 0
int remove_sourceroute(struct split_ip_msg *msg) {
  struct source_header *s;
  struct rinstall_header *rih;
  struct generic_header *g_hdr;
  uint8_t removeSource = 1;
  if (msg->hdr.nxt_hdr == NXTHDR_SOURCE) {
    sh = msg->headers->hdr.sh;
    upd_source_route(sh, msg->metadata.sender);

    // Our thinking here is that if something is source_routed
    //  from inside the network and it is not destined to us
    //  then its either a rinstall being forwarded, or a path
    //  that's been set up, so we shouldn't strip it away
    if (cmpPfx(msg->hdr.ip6_dst.s6_addr, __my_address.s6_addr) &&
        msg->hdr.ip6_dst.s6_addr16[7] != __my_address.s6_addr16[7]) {
/*         ((msg->hdr.ip6_dst.s6_addr[14] != __my_address[14] || */
/*           msg->hdr.ip6_dst.s6_addr[15] != __my_address[15]))) { */
      info("Packet with source header not destined for me\n");
  
      if ((sh->dispatch & IP_EXT_SOURCE_INVAL) != IP_EXT_SOURCE_INVAL) {
        debug("Removing invalid source header\n");
        removeSource = 0;
      }
      
      if ((sh->dispatch & IP_EXT_SOURCE_CONTROLLER) == IP_EXT_SOURCE_CONTROLLER) {
        debug("WE sent this packet! dropping...\n");
        return 1;
      }
    

      // If this is an rinstall header moving through, we need to
      //  updated the current position of the path, similar to
      //  what we do for source headers.
      if (sh->nxt_hdr == NXTHDR_INSTALL) {
        rih = msg->headers->next->hdr.rih;
        rih->current++;
        info("Incrementing current of rih to 0x%x\n", rih->current);
      }
    }
    if (removeSource) {
      msg->hdr.nxt_hdr = sh->nxt_hdr;
      msg->hdr.plen = htons(ntohs(msg->hdr.plen) - sh->len);
      g_hdr = msg->headers;
      msg->headers = msg->headers->next;
      free(g_hdr);
    }
  }
  return 0;
}
#endif

void handle_serial_packet(struct split_ip_msg *msg) {
  path_t* tPath;
  path_t* i;
#ifdef CENTRALIZED_ROUTING
  uint8_t flags = 0x00;
#endif
  if (ntohs(msg->hdr.plen) > INET_MTU - sizeof(struct ip6_hdr)) {
    warn("handle_ip_packet: too long: 0x%x\n", ntohs(msg->hdr.plen));
    return;
  }

  // print_ip_packet(msg);
  print_ip_packet(msg);
  if (process_extensions(msg))
    return;

  if (cmpPfx(msg->hdr.ip6_dst.s6_addr, __my_address.s6_addr) && 
      msg->hdr.ip6_dst.s6_addr16[7] != __my_address.s6_addr16[7]) {
      debug("Received packet destined to 0x%x\n", msg->hdr.ip6_dst.s6_addr[15]); 
      stats.fw_pkts++;
    
     // If this packet is not source routed, check to see if we're on the best path before
     //  issuing a route install
       tPath = nw_get_route(ntohs(msg->hdr.ip6_src.s6_addr16[7]), ntohs(msg->hdr.ip6_dst.s6_addr16[7]));
        for (i = tPath; i != NULL; i = i->next) {
          if (i->node == ntohs(__my_address.s6_addr16[7])) {
            debug("Not installing route for packet from 0x%x to 0x%x (on best path)\n", 
                  ntohs(msg->hdr.ip6_src.s6_addr16[7]), ntohs(msg->hdr.ip6_dst.s6_addr16[7]));
            nw_free_path(tPath);
            ip_to_pan(msg);
            return;
          }
        }
        nw_free_path(tPath);
        // }
      
      // We send the route installation packet before forwarding the actual
      //  packet, with the thinking being that the route can be set up, in
      //  case acks are issued by the destination on the packet
      //
      // We have to first select the flags that we want:
     
      //  At this point, if it's not source routed, then this packet
      //  shouldn't be coming through us so we install a route
        // if (msg->hdr.nxt_hdr != NXTHDR_SOURCE) {
        debug("installing route for packet from 0x%x to 0x%x\n", 
              ntohs(msg->hdr.ip6_src.s6_addr16[7]), ntohs(msg->hdr.ip6_dst.s6_addr16[7]));
#ifdef CENTRALIZED_ROUTING
#ifndef FULL_PATH_INSTALL
        flags = HYDRO_METHOD_SOURCE | HYDRO_INSTALL_REVERSE;
#else
        flags = HYDRO_METHOD_HOP | HYDRO_INSTALL_REVERSE;
#endif
        //        install_route(msg, flags);
#endif
        // } else {
        // info("Packet had a source header so no route install\n"); 
        // }
      ip_to_pan(msg);
      // do routing
  } else {
    // give it to linux
    // need to remove route info here.
    stats.rx_pkts++;
    tun_write(tun_fd, msg);
    debug("tun_write: wrote 0x%x bytes\n", sizeof(struct ip6_hdr) + ntohs(msg->hdr.plen));
  }
}

void add_header_list(struct split_ip_msg *msg) {
  uint8_t nxt_hdr;
  struct generic_header *g_hdr, **g_list;
  struct ip6_ext *ext = (struct ip6_ext *)msg->next;
  uint16_t hdr_len = 0;
  // debug("add_header_list for message destined to 0x%x\n", ntohs(msg->hdr.ip6_dst.s6_addr16[7]));
  nxt_hdr = msg->hdr.nxt_hdr;
  msg->headers = NULL;
  g_list = &(msg->headers);
  while (EXTENSION_HEADER(nxt_hdr)) {
    g_hdr = (struct generic_header *)malloc(sizeof(struct generic_header));
    g_hdr->payload_malloced = 0;
    g_hdr->hdr.ext = ext;
    g_hdr->next = NULL;
    *g_list = g_hdr;
    g_list = &g_hdr->next;

    g_hdr->len = ext->len;
    
    nxt_hdr = ext->nxt_hdr;
    ext = (struct ip6_ext *)(((uint8_t *)ext) + ext->len);
    
    hdr_len += g_hdr->len;
  }
  if (COMPRESSIBLE_TRANSPORT(nxt_hdr)) {
      int transport_len;
      switch (nxt_hdr) {
      case IANA_UDP:
        transport_len = sizeof(struct udp_hdr); break;
      }

      g_hdr = (struct generic_header *)malloc(sizeof(struct generic_header));
      g_hdr->payload_malloced = 0;
      g_hdr->hdr.ext = ext;
      g_hdr->next = NULL;
      *g_list = g_hdr;
      g_list = &g_hdr->next;

      g_hdr->len = transport_len;
      ext = (struct ip6_ext *)(((uint8_t *)ext) + transport_len);
      hdr_len += transport_len;
  }

  msg->data = (uint8_t *)ext;
  msg->data_len = ntohs(msg->hdr.plen) - hdr_len;
}

#ifdef CENTRALIZED_ROUTING
/*
 * Given a source and destination, send a source-routed route install message
 * that will install the correct routes.
 *
 * NOTE: Make sure that this is the correct way to create a new packet
 */
time_t last_install;
void install_route(struct split_ip_msg *amsg, uint8_t flags) {
  uint8_t buf[sizeof(struct split_ip_msg) + INET_MTU];
  struct split_ip_msg *msg = (struct split_ip_msg *)buf;
  int offset = 0;


  struct ip6_ext *ext = (struct ip6_ext *)(msg->next);
  struct tlv_hdr *tlv = (struct tlv_hdr *)(ext + 1);
  struct rinstall_header *rih = (struct rinstall_header *)(tlv + 1);

  path_t* path = nw_get_route(ntohs(amsg->hdr.ip6_src.s6_addr16[7]), ntohs(amsg->hdr.ip6_dst.s6_addr16[7]));
  path_t* i;
  time_t current_time;

#if 0
  time(&current_time);

  if (current_time < last_install + 2) {
    debug("Not sending install\n");
    return;
  }
  time(&last_install);
#endif 


  if (path == NULL || path->isController) return;
  fprintf(stderr, "install_route for src: 0x%x, dest: 0x%x, flags: %x\n", 
          ntohs(amsg->hdr.ip6_src.s6_addr16[7]), ntohs(amsg->hdr.ip6_dst.s6_addr16[7]), path->length);
  if (path->length > 10) return;

  memset((uint8_t *)&msg->hdr, 0, sizeof(struct ip6_hdr));

  // Set IP Header options
  msg->hdr.hlim = 0x64; // CHECK THIS
  msg->hdr.nxt_hdr = IPV6_DEST;
  msg->hdr.vlfc[0] = IPV6_VERSION << 4;
  msg->flow_id = local_seqno++;

  memcpy(&msg->hdr.ip6_src, &__my_address, sizeof(struct in6_addr));
  memcpy(&msg->hdr.ip6_dst, &amsg->hdr.ip6_src, sizeof(struct in6_addr));
  msg->headers = NULL;

  ext->nxt_hdr = IPV6_NONEXT;
  ext->len = sizeof(struct ip6_ext) + sizeof(struct tlv_hdr) + sizeof(struct rinstall_header)
    + (path->length * sizeof(uint16_t));

  tlv->len = ext->len - sizeof(struct ip6_ext);
  tlv->type = TLV_TYPE_INSTALL;

  // Setup rinstall_header
 // Size is longer because we put the src in there
  rih->flags = flags;
  rih->match.src = htons(T_INVAL_NEIGH);
  rih->match.dest = amsg->hdr.ip6_dst.s6_addr16[7]; 
  rih->path_len = path->length;

  // Convert to host so add_headers_list works
  msg->hdr.plen = htons(ext->len); 

  info("install_route len: 0x%x\n", rih->path_len);

  fprintf(stderr, "from 0x%x to 0x%x [%i]: ", 
          ntohs(amsg->hdr.ip6_src.s6_addr16[7]), ntohs(amsg->hdr.ip6_dst.s6_addr16[7]), path->length);
  // rih->path[0] = amsg->hdr.ip6_src.s6_addr16[7]; //htons(l2fromIP(amsg->hdr.ip6_src.s6_addr));
  for (i = path; i != NULL; i = i->next) {
    fprintf(stderr, "0x%x ", i->node);
    rih->path[offset++] = htons(i->node);
  }

  nw_free_path(path);

  add_header_list(msg);
  print_ip_packet(msg);
  loglevel_t old_lvl = log_setlevel(LOGLVL_DEBUG);
  ip_to_pan(msg);
  log_setlevel(old_lvl);
  free_split_msg(msg);
}

void uninstall_route(uint16_t n1, uint16_t n2) {
  uint8_t buf[sizeof(struct split_ip_msg) + INET_MTU];
  struct split_ip_msg *msg = (struct split_ip_msg *)buf;
  struct ip6_ext *ext = (struct ip6_ext *)(msg->next);
  struct tlv_hdr *tlv = (struct tlv_hdr *)(ext + 1);
  struct rinstall_header *rih = (struct rinstall_header *)(tlv + 1);

  // Set IP Header options
  msg->hdr.hlim = 0x64; // CHECK THIS
  msg->hdr.nxt_hdr = IPV6_DEST;
  msg->hdr.vlfc[0] = IPV6_VERSION << 4;
  msg->flow_id = local_seqno++;

  memcpy(&msg->hdr.ip6_src, &__my_address, sizeof(struct in6_addr));
  memcpy(&msg->hdr.ip6_dst, &__my_address, sizeof(struct in6_addr));
  msg->hdr.ip6_dst.s6_addr16[7] = htons(n1);
  msg->headers = NULL;

  ext->nxt_hdr = IPV6_NONEXT;
  ext->len = sizeof(struct ip6_ext) + sizeof(struct tlv_hdr) + sizeof(struct rinstall_header);

  tlv->len = ext->len - sizeof(struct ip6_ext);
  tlv->type = TLV_TYPE_INSTALL;

  // Convert to host so add_headers_list works
  msg->hdr.plen = htons(ext->len); 

  rih->flags = HYDRO_INSTALL_UNINSTALL_MASK | HYDRO_METHOD_SOURCE;
  rih->match.src = htons(n1);
  rih->match.dest = htons(n2);
  rih->path_len = 0;
    

  add_header_list(msg);
  print_ip_packet(msg);
  loglevel_t old_lvl = log_setlevel(LOGLVL_DEBUG);
  ip_to_pan(msg);
  log_setlevel(old_lvl);
  free_split_msg(msg);
}

#endif

/*
 * read data from the tun device and send it to the serial port
 * does also fragmentation
 */
int tun_input()
{
  uint8_t buf[sizeof(struct split_ip_msg) + INET_MTU];
  struct split_ip_msg *msg = (struct split_ip_msg *)buf;
  int len;

  len = tun_read(tun_fd, (void *)(&msg->pi), INET_MTU + sizeof(struct ip6_hdr));

  if (len <= 0) {
    return 0;
  }
  debug("tun_read: read 0x%x bytes\n", len);

  if ((msg->hdr.vlfc[0] >> 4) != IPV6_VERSION) {
    warn("tun_read: discarding non-ip packet\n");
    goto fail;
  }
  if (ntohs(msg->hdr.plen) > INET_MTU - sizeof(struct ip6_hdr)) {
    debug("tun_input: dropping packet due to length: 0x%x\n", ntohs(msg->hdr.plen));
    goto fail;
  }
  if (msg->hdr.nxt_hdr == 0) {
    debug("tun_input: dropping packet with IPv6 options\n");
    goto fail;
  }
  
  add_header_list(msg);
  msg->flow_id = local_seqno++;

  ip_to_pan(msg);

  free_split_msg(msg);
  
  return 1;
 fail:
  /* error("Invalid packet or version received\n"); */
  return 1;
}

/* ------------------------------------------------------------------------- */
/* handling of data arriving on the serial port */

reconstruct_t reconstructions [N_RECONSTRUCTIONS];

void age_reconstructions() {
  int i;
  for (i = 0; i < N_RECONSTRUCTIONS; i++) {
    // switch "active" buffers to "zombie"
    if (reconstructions[i].timeout == T_ACTIVE) {
      reconstructions[i].timeout = T_ZOMBIE;
    } else if (reconstructions[i].timeout == T_ZOMBIE) {
      reconstructions[i].timeout = T_UNUSED;
      free(reconstructions[i].buf);
      reconstructions[i].buf = NULL;
    }
  }
}


reconstruct_t *getReassembly(packed_lowmsg_t *lowmsg) {
  int i, free_spot = N_RECONSTRUCTIONS + 1;
  uint16_t mytag, size;
  if (getFragDgramTag(lowmsg, &mytag)) return NULL;
  if (getFragDgramSize(lowmsg, &size)) return NULL;
  
  for (i = 0; i < N_RECONSTRUCTIONS; i++) {
    if (reconstructions[i].timeout > T_UNUSED && reconstructions[i].tag == mytag) {
      reconstructions[i].timeout = T_ACTIVE;
      return &(reconstructions[i]);
    }
    if (reconstructions[i].timeout == T_UNUSED) free_spot = i;
  }
  // allocate a new struct for doing reassembly.
  if (free_spot != N_RECONSTRUCTIONS + 1) {
    // if we don't get the packet with the protocol in it first, we
    // don't know who to ask for a buffer, and so give up.

    reconstructions[free_spot].tag = mytag;

    reconstructions[free_spot].size = size;
    reconstructions[free_spot].buf = malloc(size + offsetof(struct split_ip_msg, hdr));
    reconstructions[free_spot].bytes_rcvd = 0;
    reconstructions[free_spot].timeout = T_ACTIVE;

    debug("checking buffer size 0x%x\n", reconstructions[free_spot].size);
    if (reconstructions[free_spot].buf == NULL) {
      reconstructions[free_spot].timeout = T_UNUSED;
      return NULL;
    }
    return &(reconstructions[free_spot]);
  }
  return NULL;
}

/* 
 * read data on serial port and send it to the tun interface
 * does fragment reassembly
 */
int serial_input() {
    packed_lowmsg_t pkt;
    reconstruct_t *recon;
    struct split_ip_msg *msg;
    IEEE154_header_t *mac_hdr;
    
    uint8_t *ser_data = NULL;	        /* data read from serial port */
    int ser_len = 0;                    /* length of data read from serial port */
    uint8_t shortMsg[INET_MTU];
    uint8_t *payload;

#ifdef SF_SRC
    int rv = 0;
#else
    int rv = 1;
#endif

    /* read data from serial port */
    ser_data = (uint8_t *)read_pan_packet(&ser_len);

    /* process the packet we have received */
    if (ser_len && ser_data) {
      if (ser_data[0] != TOS_SERIAL_802_15_4_ID) {
        handle_other_pkt(ser_data, ser_len);
        goto discard_packet;
      }
      mac_hdr = (IEEE154_header_t *)(ser_data + 1);

      // size is  one for the length byte, minus two for the checksum
      pkt.len = mac_hdr->length - MAC_HEADER_SIZE - MAC_FOOTER_SIZE;
      // add one for the dispatch byte.
      pkt.data = ser_data + 1 + sizeof(IEEE154_header_t);

      // for some reason these are little endian so we don't do any conversion.
      pkt.src = mac_hdr->src;
      pkt.dst = mac_hdr->dest;

      log_dump_serial_packet(ser_data, ser_len);

      pkt.headers = getHeaderBitmap(&pkt);
      if (pkt.headers == LOWPAN_NALP_PATTERN) goto discard_packet;

      stats.rx_frags++;
      stats.rx_bytes += ser_len - 1;
      if (hasFrag1Header(&pkt) || hasFragNHeader(&pkt)) {
        unpack_info_t u_info;
        uint8_t amount_here;

        recon = getReassembly(&pkt);
        if (recon == NULL || recon->buf == NULL) goto discard_packet;
        msg = (struct split_ip_msg *)recon->buf;
        msg->prev_hop = pkt.src;

        if (hasFrag1Header(&pkt)) {
          if (unpackHeaders(&pkt, &u_info,
                            (uint8_t *)&msg->hdr, recon->size) == NULL) goto discard_packet;
          amount_here = pkt.len - (u_info.payload_start - pkt.data);
          // adjustPlen(&msg->hdr, &u_info);

          ip_memcpy(u_info.header_end, u_info.payload_start, amount_here);
          recon->bytes_rcvd = sizeof(struct ip6_hdr) + u_info.payload_offset + amount_here;
        } else {
          uint8_t offset_cmpr;
          uint16_t offset;
          if (getFragDgramOffset(&pkt, &offset_cmpr)) goto discard_packet;
          offset = offset_cmpr * 8;
          payload = getLowpanPayload(&pkt);
          amount_here = pkt.len - (payload - pkt.data);

          if (offset + amount_here > recon->size) goto discard_packet;
          ip_memcpy(((uint8_t *)&msg->hdr) + offset, payload, amount_here);
          recon->bytes_rcvd += amount_here;
          
          if (recon->size == recon->bytes_rcvd) {
            // got all the fragments...
            debug ("serial: reconstruction finished\n");
            add_header_list(msg);

            msg->metadata.sender = pkt.src;

            handle_serial_packet(msg);

            recon->timeout = T_UNUSED;
            free_split_msg(msg);
            free(recon->buf);
          }
        }

      } else {
        unpack_info_t u_info;
        // u_info.rih = NULL;
        msg = (struct split_ip_msg *)shortMsg;
        msg->prev_hop = pkt.src;

        if (unpackHeaders(&pkt, &u_info,
                          (uint8_t *)&msg->hdr, INET_MTU) == NULL) goto discard_packet;
        if (ntohs(msg->hdr.plen) > INET_MTU - sizeof(struct ip6_hdr)) goto discard_packet;
        // adjustPlen(&msg->hdr, &u_info);

        msg->metadata.sender = pkt.src;
/*         if (u_info.rih != NULL) */
/*           info("Has a rinstall_header for src 0x%x with match: 0x%x\n",  */
/*                pkt.src, ntohs(u_info.rih->match.dest));; */

        ip_memcpy(u_info.header_end, u_info.payload_start, ntohs(msg->hdr.plen));

        add_header_list(msg);
        
        handle_serial_packet(msg);
        free_split_msg(msg);
      }
    } else {
      //printf("no data on serial port, but FD triggered select\n");
      rv = 0;
    }
  discard_packet:
    // debug("serial_input: discard packet\n");
    free(ser_data);
    return rv;
}

void print_stats(int fd, int argc, char **argv) {
  VTY_HEAD;
  
  VTY_printf("Up since %s", ctime(&stats.boot_time));
  VTY_printf("  receive  packets: %lu fragments: %lu bytes: %lu\n",
             stats.rx_pkts, stats.rx_frags, stats.rx_bytes);
  VTY_printf("  transmit packets: %lu fragments: %lu bytes: %lu\n",
             stats.tx_pkts, stats.tx_frags, stats.tx_bytes);
  VTY_printf("  forward  packets: %lu\n", stats.fw_pkts);
  VTY_flush();
}

void print_help(int fd, int argc, char **argv) {
  VTY_HEAD;
  VTY_printf("ip-driver console\r\n");
  VTY_printf("  conf      : print configuration info\r\n");
  VTY_printf("  stats     : print statistics\r\n");
  VTY_printf("  shutdown  : shutdown the driver\r\n");
  VTY_printf("  chan <c>  : switch to channel 'c'\r\n");
  VTY_printf("  dot <dotfile>: print dot-file of topology\r\n");
  VTY_printf("  log {DEBUG INFO WARN ERROR FATAL}: set loglevel\r\n");
  
  VTY_printf("\r\n Routing commands:\r\n");
  VTY_printf("  inval <nodeid> : invalidate a router\r\n");
  VTY_printf("  add <n1> <n2>  : add a persistent link between n1 and n2\r\n");
  VTY_printf("  links          : print link detail\r\n");
  VTY_printf("  routes         : print routes\r\n");
  VTY_printf("  newroutes      : recalculate routes\r\n");
  VTY_printf("  controller <n> : add a new controller\r\n");
#ifdef CENTRALIZED_ROUTING
  VTY_printf("  install <HOP | SRC> <n1> <n2> [reverse]: install a route between n1 and n2\r\n");
  VTY_printf("  uninstall <n1> <n2>: uninstall a route between n1 and n2\r\n");
#endif
  
  VTY_printf("\r\n");
  VTY_printf("  help: print this help\r\n");
  VTY_flush();
}

void sh_loglevel(int fd, int argc, char **argv) {
  VTY_HEAD;
  int i;

  if (argc != 2) return;
  for (i = 0; i < 5; i++) {
    if (strcmp(log_names[i], argv[1]) == 0) {
      VTY_printf("setting verbosity to %s\r\n", log_names[i]);
      log_setlevel(i);
    }
  }
  VTY_flush();
}

void sh_dotfile(int fd, int argc, char **argv) {
  VTY_HEAD;
  if (argc == 2) {
    VTY_printf("writing topology to %s\r\n", argv[1]);
    nw_print_dotfile(argv[1]);
  } else {
    VTY_printf("error: include a filename!\r\n");
  }
  VTY_flush();
}

void sh_chan(int fd, int argc, char **argv) {
  VTY_HEAD;
  if (argc != 2) {
    VTY_printf("%s <channel>\r\n", argv[0]);
  } else {
    int channel = atoi(argv[1]);
    if (channel < 11 || channel > 26) {
      VTY_printf("channel must be in [11:26]\r\n");
    } else {
      driver_config.channel = channel;
      VTY_printf("setting channel to %i\r\n", channel);
      configure_setparms(&driver_config, CONFIG_SET_PARM);
    }
  }
  VTY_flush();
}

#ifdef CENTRALIZED_ROUTING
void sh_install(int fd, int argc, char **argv) {
  VTY_HEAD;
  int flags = 0;
  struct split_ip_msg msg;
  if (argc < 4) {
    goto usage;
  } 
  if (strcmp("HOP", argv[1]) == 0) 
    flags |= HYDRO_METHOD_HOP;
  else if (strcmp("SRC", argv[1]) == 0) {
    flags |= HYDRO_METHOD_SOURCE;
  } else goto usage;

  argc -= 4;
  while (argc > 0) {
    if (argv[argc+3][0] == 'R') {
      flags |= HYDRO_INSTALL_REVERSE;
    } else goto usage;
    argc--;
  }
  memset(&msg, 0, sizeof(struct split_ip_msg));
  memcpy(msg.hdr.ip6_src.s6_addr, __my_address.s6_addr, 8);
  memcpy(msg.hdr.ip6_dst.s6_addr, __my_address.s6_addr, 8);
  msg.hdr.ip6_src.s6_addr16[7] = htons(atoi(argv[2]));
  msg.hdr.ip6_dst.s6_addr16[7] = htons(atoi(argv[3]));

  VTY_printf("installing route between 0x%x and 0x%x\r\n", atoi(argv[2]), atoi(argv[3]));
  install_route(&msg, flags);

  VTY_flush();
  return;
 usage:
  VTY_printf("%s <HOP | SRC> <n1> <n2> [REV]\r\n", argv[0]);
  VTY_flush();
}

void sh_uninstall(int fd, int argc, char **argv) {
  VTY_HEAD;
  if (argc != 3) {
    VTY_printf("%s <n1> <n2>\r\n", argv[0]);
    VTY_flush();
    return;
  }
  int n1 = atoi(argv[1]);
  int n2 = atoi(argv[2]);
  VTY_printf("uninstalling route from 0x%x to 0x%x\r\n", n1, n2);
  uninstall_route(n1, n2);
  VTY_flush();
}
#endif

void sh_controller(int fd, int argc, char **argv) {
  VTY_HEAD;
  if (argc != 2) {
    VTY_printf("%s <cid>\r\n", argv[0]);
  } else {
    int n = atoi(argv[1]);
    get_insert_router(n);
    nw_add_controller(n);
  }
  VTY_flush();
}

struct vty_cmd vty_cmd_list[] = {{"help", print_help},
                                 {"stats",  print_stats},
                                 {"links", nw_print_links},
                                 {"route", nw_print_routes},
                                 {"newroutes", nw_test_routes},
                                 {"add", nw_add_sticky_edge},
                                 {"inval", nw_inval_node_sh},
                                 {"conf", config_print},
                                 {"log", sh_loglevel},
                                 {"dot", sh_dotfile},
                                 {"chan", sh_chan},
#ifdef CENTRALIZED_ROUTING
                                 {"install", sh_install},
                                 {"uninstall", sh_uninstall},
#endif
                                 {"controller", sh_controller},
                                 {"shutdown", (void(*)(int,int,char**))driver_shutdown}};

/* shifts data between the serial port and the tun interface */
int serial_tunnel(int tun_fd) {
  fd_set fs;
  int maxfd = -1;
  int usecs_remain = KEEPALIVE_INTERVAL;
  time_t last_aging, current_time;
  time(&last_aging);
#ifndef SF_SRC
  int pan_fd = opt_listenonly ? -1 : serial_source_fd(ser_src);
#else
  int pan_fd = opt_listenonly ? -1 : sf_fd;
#endif

  while (1) {
    int n_fds;
    struct timeval tv;
    if (do_shutdown) return 0;

    FD_ZERO(&fs);

    if (opt_listenonly) {
      maxfd = -1;
    } else {
      FD_SET(tun_fd, &fs);
      FD_SET(pan_fd, &fs);

      maxfd = max(tun_fd, pan_fd);
    }

    if (radvd_fd >= 0) {
      FD_SET(radvd_fd, &fs);
      maxfd = max(radvd_fd, maxfd);
    }

    maxfd = max(vty_add_fds(&fs), maxfd);
    maxfd = max(routing_add_fds(&fs), maxfd);

    // having a timeout also means that we poll for new packets every
    // so often, which is apparently A Good Thing
    tv.tv_sec  = 0;
    tv.tv_usec = KEEPALIVE_TIMEOUT;
    if ((n_fds = select(maxfd + 1, &fs, NULL, NULL, &tv)) < 0) {
      continue;
    }
    usecs_remain -= (KEEPALIVE_TIMEOUT - tv.tv_usec);
    if (usecs_remain <= 0) {
      if (keepalive_needed) {
        configure_setparms(&driver_config, CONFIG_KEEPALIVE);
      } else keepalive_needed = 1;

      usecs_remain = KEEPALIVE_INTERVAL;
    }
    
    if (!opt_listenonly) {
      int more_data;
      /* check for data */
      do {
        more_data = tun_input();
        more_data = serial_input() || more_data ;
      } while (more_data);
    }

    vty_process(&fs);
    routing_process(&fs);

    if (radvd_fd >= 0 && FD_ISSET(radvd_fd, &fs)) {
      radvd_process();
    }

    /* end of data available */
    time(&current_time);
    if (current_time > last_aging + (FRAG_EXPIRE_TIME / 1024)) {
      last_aging = current_time;
      age_reconstructions();
    }
  }

}

int main(int argc, char **argv) {
  int i, c;

  time(&stats.boot_time);

  log_init();
  while ((c = getopt(argc, argv, "c:lt")) != -1) {
    switch (c) {
    case 'c':
      def_configfile = optarg;
      break;
    case 'l':
      opt_listenonly = 1;
      break;
    case 't':
      info("TrackFlows: will insert flow id on outgoing packets\n");
      opt_trackflows = 1;
      break;
    default:
      fatal("Invalid command line argument.\n");
      exit(1);
    }
  }

  if (argc - optind != 2) {
#ifndef SF_SRC
    fatal("usage: %s [-c config] [-n] <device> <rate>\n", argv[0]);
#else
    fatal("usage: %s [-c config] <host> <port>\n", argv[0]);
#endif
    exit(2);
  }
    
  fifo_open();
  signal(SIGINT,  driver_shutdown);

  if (config_parse(def_configfile, &driver_config) != 0) {
    fatal ("config parse of %s failed!\n", def_configfile);
    exit(1);
  }
  globalPrefix = 1;
  memcpy(&__my_address, &driver_config.router_addr, sizeof(struct in6_addr));


  struct vty_cmd_table t;
  short vty_port = 6106;
  t.n = sizeof(vty_cmd_list) / sizeof(struct vty_cmd);
  t.table = vty_cmd_list;
  if (vty_init(&t, vty_port) < 0) {
    error("could not start debug console server\n");
    error("the console will be available only on stdin\n");
  } else {
    info("telnet console server running on port %i\n", vty_port);
  }


  dev[0] = 0;
  if (opt_listenonly) {
    tun_fd = -1;
#ifndef SF_SRC
    ser_src = NULL;
#endif
  } else {
    /* create the tunnel device */
    tun_fd = tun_open(dev);
    if (tun_fd < 1) {
      fatal("Could not create tunnel device. Fatal.\n");
      return 1;
    } else {
      info("created tun device: %s\n", dev);
    }
    if (tun_setup(dev, &__my_address) < 0) {
      fatal("configuring the tun failed; aborting\n");
      perror("tun_setup");
      return 1;
    }
    
    
    for (i = 0; i < N_RECONSTRUCTIONS; i++) {
      reconstructions[i].timeout = T_UNUSED;
    }

    /* open the serial port */
#ifndef SF_SRC
    ser_src = open_serial_source(argv[optind], platform_baud_rate(argv[optind + 1]),
                                 1, stderr_msg);
    if (!ser_src) {
      fatal("Couldn't open serial port at %s:%s\n", argv[optind], argv[optind + 1]);
      exit(1);
    }
#else
    sf_fd = open_sf_source(argv[optind], atoi(argv[optind + 1]));
    if (sf_fd < 0) {
      fatal("Couldn't connect to serial forwarder sf@%s:%s\n", argv[optind], argv[optind + 1]);
      exit(1);
    }
#endif

#ifndef SIM
  configure_reboot();
#endif

  }

  if (routing_init(&driver_config, dev) < 0) {
    fatal("could not start routing engine!\n");
    exit(1);
  }

  /* start tunneling */
  serial_tunnel(tun_fd);

  /* clean up */
  info("driver shutting down\n");
  vty_shutdown();
  if (!opt_listenonly)  {
    tun_close(tun_fd, dev);
    close_pan();
  }
  fifo_close();
  return 0;
}
