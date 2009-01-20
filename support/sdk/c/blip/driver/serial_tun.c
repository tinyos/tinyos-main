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

#define min(a,b) ( (a>b) ? b : a )
#define max(a,b) ( (a>b) ? a : b )

int tun_fd, radvd_fd = -1;
int radvd_init(char *ifname, struct config *c);
void radvd_process();

#ifndef SIM
serial_source ser_src;
#define write_pan_packet(DATA, LEN) write_serial_packet(ser_src, DATA, LEN)
#define read_pan_packet(LENP) read_serial_packet(ser_src, LENP)
#else
int sf_fd;
#define write_pan_packet(DATA, LEN) write_sf_packet(sf_fd, DATA, LEN)
#define read_pan_packet(LENP) read_sf_packet(sf_fd, LENP)
#endif

enum {
  N_RECONSTRUCTIONS = 10,
};

/*
 * This is not the right way to detect we're on that platform, but I
 * can't find a better macro.
 */ 
#ifdef __TARGET_mips__
char *def_configfile = "/etc/lowpan/serial_tun.conf";
#else
char *def_configfile = "serial_tun.conf";
#endif

#ifdef DBG_TRACK_FLOWS
FILE *dbg_file;
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

void configure_setparms(struct config *c) {
  uint8_t buf[sizeof(config_cmd_t) + 1];
  config_cmd_t *cmd = (config_cmd_t *)(&buf[1]);
  memset(buf, 0, sizeof(config_cmd_t) + 1);
  buf[0] = TOS_SERIAL_DEVCONF;
  cmd->cmd = CONFIG_SET_PARM;
  cmd->rf.addr = c->router_addr.s6_addr16[7]; // is network byte-order
  cmd->rf.channel = c->channel;
  cmd->retx.retries = htons(10);
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
      configure_setparms(&driver_config);
      break;
    default:
      info("interface device successfully initialized\n");
      config_success = 1;

      /* put this here because we already use SIGALRM for the
         configure timeout, and radvd needs it for its own timer. */
      if ((radvd_fd = radvd_init(dev, &driver_config)) < 0) {
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
void write_radio_header(uint8_t *serial, hw_addr_t dest, uint16_t payload_len) {
#ifndef SIM
  IEEE154_header_t *radioPacket = (IEEE154_header_t *)(serial + 1);
  radioPacket->length = payload_len + MAC_HEADER_SIZE + MAC_FOOTER_SIZE 
#ifdef DBG_TRACK_FLOWS
    + sizeof(struct flow_id);
#else
  ;
#endif
  // don't include the length byte
  radioPacket->fcf = htons(0x4188);
  // dsn will get set on mote
  radioPacket->destpan = 0;
  radioPacket->dest = htole16(dest);
  // src will get set on mote 
  
  serial[0] = SERIAL_TOS_SERIAL_802_15_4_ID;
#else
  serial_header_t *serialHeader = (serial_header_t *)(serial + 1);
  serialHeader->length = payload_len
#ifdef DBG_TRACK_FLOWS
    + sizeof(struct flow_id);
#else
  ;
#endif
  serialHeader->dest = htons(dest);
  serialHeader->type = 0;

  serial[0] = 0;
#endif
}

void send_fragments (struct split_ip_msg *msg, hw_addr_t dest) {
  int result;
  uint16_t frag_len;
  fragment_t progress;
  uint8_t serial[LOWPAN_LINK_MTU + 1];
#ifndef SIM
  IEEE154_header_t *radioPacket = (IEEE154_header_t *)(serial + 1);
#define PKTLEN(X) ((X)->length + 2)
#else
  serial_header_t *radioPacket = (serial_header_t *)(serial + 1);
#define PKTLEN(X) ((X)->length + sizeof(serial_header_t) + 1)
#endif

  uint8_t *lowpan = (uint8_t *)(radioPacket + 1);

#ifdef DBG_TRACK_FLOWS
#define LOWPAN_PAYLOAD_LENGTH (LOWPAN_LINK_MTU - MAC_HEADER_SIZE \
                              - MAC_FOOTER_SIZE - sizeof(struct flow_id))
  lowpan += sizeof(struct flow_id);
#else 
#define LOWPAN_PAYLOAD_LENGTH (LOWPAN_LINK_MTU - MAC_HEADER_SIZE \
                              - MAC_FOOTER_SIZE)
#endif

  progress.offset = 0;

  // and IEEE 802.15.4 header
  // write_radio_header(serial, dest, frag_len);
#ifdef DBG_TRACK_FLOWS
#ifndef SIM
  ip_memcpy(serial + 1 + sizeof(IEEE154_header_t), &msg->id, sizeof(struct flow_id));
#else
  ip_memcpy(serial + 1 + sizeof(serial_header_t), &msg->id, sizeof(struct flow_id));
#endif
  if (dest != 0xffff) {
    fprintf(dbg_file, "DEBUG (%i): %i\t%i\t%i\t%i\t%i\t%i\t%i\n",
            100, msg->id.src, msg->id.dst, msg->id.id, msg->id.seq,
            msg->id.nxt_hdr, 100, dest);
    fflush(dbg_file);
  }
#endif

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
  uint16_t dest;

  debug("ip_to_pan\n");
  print_ip_packet(msg);

  // if this packet has a source route (rinstall header, or prexisting
  // source header, we don't want to mess with it
  switch (routing_is_onehop(msg)) {
  case ROUTE_MHOP:
    debug("Multihop packet");
    if (routing_insert_route(msg)) goto fail;
    break;
    
  case ROUTE_NO_ROUTE:
    info("destination unreachable: 0x%x: dropping\n", ntohs(msg->hdr.ip6_dst.s6_addr16[7]));
    return 0;
  }


  dest = routing_get_nexthop(msg);
  debug("next hop: 0x%x\n", dest);
  send_fragments(msg, dest);
  return 0;
 fail:
  error("ip_to_pan: no route to host\n");
  return 1;
}

void upd_source_route(struct source_header *sh, hw_addr_t addr) {
  if (sh->current < SH_NENTRIES(sh)) {
    sh->hops[sh->current] = leton16(addr);
    sh->current++;
  }
}

int remove_sourceroute(struct split_ip_msg *msg) {
  struct source_header *sh;
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


void handle_serial_packet(struct split_ip_msg *msg) {
  path_t* tPath;
  path_t* i;
#ifdef DBG_TRACK_FLOWS
  uint8_t flags = 0x00;
#endif
  if (ntohs(msg->hdr.plen) > INET_MTU - sizeof(struct ip6_hdr)) {
    warn("handle_ip_packet: too long: 0x%x\n", ntohs(msg->hdr.plen));
    return;
  }

  // print_ip_packet(msg);
  // if this packet has a source route that we inserted, we need to
  // drop it to prevent loops.
  if (remove_sourceroute(msg))
    return;
  routing_proc_msg(msg);
  remove_sourceroute(msg);

  if (cmpPfx(msg->hdr.ip6_dst.s6_addr, __my_address.s6_addr) && 
      msg->hdr.ip6_dst.s6_addr16[7] != __my_address.s6_addr16[7]) {
/*       ((msg->hdr.ip6_dst.s6_addr[14] != __my_address[14] || */
/*         msg->hdr.ip6_dst.s6_addr[15] != __my_address[15]))) { */
      info("Received packet destined to 0x%x\n", msg->hdr.ip6_dst.s6_addr[15]);
     
     // If this packet is not source routed, check to see if we're on the best path before
     //  issuing a route install
     if (msg->hdr.nxt_hdr != NXTHDR_SOURCE) { 
       tPath = nw_get_route(ntohs(msg->hdr.ip6_src.s6_addr16[7]), ntohs(msg->hdr.ip6_dst.s6_addr16[7]));
        for (i = tPath; i != NULL; i = i->next) {
          if (i->node == ntohs(__my_address.s6_addr16[7])) {
	    info("Not installing route for packet from 0x%x to 0x%x (on best path)\n", 
                 ntohs(msg->hdr.ip6_src.s6_addr16[7]), ntohs(msg->hdr.ip6_dst.s6_addr16[7]));
            nw_free_path(tPath);
            ip_to_pan(msg);
            return;
          }
        }
        nw_free_path(tPath);
      }
      
      // We send the route installation packet before forwarding the actual
      //  packet, with the thinking being that the route can be set up, in
      //  case acks are issued by the destination on the packet
      //
      // We have to first select the flags that we want:
     
      //  At this point, if it's not source routed, then this packet
      //  shouldn't be coming through us so we install a route
      if (msg->hdr.nxt_hdr != NXTHDR_SOURCE) {
        info("installing route for packet from 0x%x to 0x%x\n", 
             ntohs(msg->hdr.ip6_src.s6_addr16[7]), ntohs(msg->hdr.ip6_dst.s6_addr16[7]));
      } else {
        info("Packet had a source header so no route install\n"); 
      }
      stats.fw_pkts++;
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
  debug("add_header_list for message destined to 0x%x\n", ntohs(msg->hdr.ip6_dst.s6_addr16[7]));
  nxt_hdr = msg->hdr.nxt_hdr;
  msg->headers = NULL;
  g_list = &(msg->headers);
  while (KNOWN_HEADER(nxt_hdr)) {
    g_hdr = (struct generic_header *)malloc(sizeof(struct generic_header));
    g_hdr->payload_malloced = 0;
    g_hdr->hdr.ext = ext;
    g_hdr->next = NULL;
    *g_list = g_hdr;
    g_list = &g_hdr->next;

    switch(nxt_hdr) {
    case IANA_UDP:
      // a UDP header terminates a chain of headers we can compress...
      g_hdr->len = sizeof(struct udp_hdr);
      ext = (struct ip6_ext *)(((uint8_t *)ext) + sizeof(struct udp_hdr));
      nxt_hdr = NXTHDR_UNKNOWN;
      break;
      // XXX : SDH : these are all "ip extension" headers and so can be treated genericlly.
    case NXTHDR_INSTALL:
      info("inserted NXTHDR_INSTALL\n");
    case NXTHDR_TOPO:
    case NXTHDR_SOURCE:
      g_hdr->len = ext->len;
      
      nxt_hdr = ext->nxt_hdr;
      ext = (struct ip6_ext *)(((uint8_t *)ext) + ext->len);
      break;
    default:
      // TODO : SDH : discard the packet here since we can get in a
      // bad place with invalid header types.  this isn't all that
      // likely, but you never know.
      break;
    }
    hdr_len += g_hdr->len;
  }
  msg->data = (uint8_t *)ext;
  msg->data_len = ntohs(msg->hdr.plen) - hdr_len;
}

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
#ifdef DBG_TRACK_FLOWS
  msg->id.src = 100;
  msg->id.dst = ntohs(msg->hdr.ip6_dst.s6_addr16[7]); //l2fromIP(msg->hdr.dst_addr);
  msg->id.id = local_seqno++;
  msg->id.seq = 0;
  msg->id.nxt_hdr = msg->hdr.nxt_hdr;
#endif

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
#ifndef SIM
    IEEE154_header_t *mac_hdr;
#else
    serial_header_t *mac_hdr;
#endif
    
    uint8_t *ser_data = NULL;	        /* data read from serial port */
    int ser_len = 0;                    /* length of data read from serial port */
    uint8_t shortMsg[INET_MTU];
    uint8_t *payload;
#ifdef DBG_TRACK_FLOWS
    struct flow_id *fl_id;
#endif

    int rv = 1;

    /* read data from serial port */
    ser_data = (uint8_t *)read_pan_packet(&ser_len);

    /* process the packet we have received */
    if (ser_len && ser_data) {
#ifndef SIM
      if (ser_data[0] != TOS_SERIAL_802_15_4_ID) {
        handle_other_pkt(ser_data, ser_len);
        goto discard_packet;
      }
      mac_hdr = (IEEE154_header_t *)(ser_data + 1);

#ifdef DBG_TRACK_FLOWS
      fl_id = (struct flow_id *)(ser_data + 1 + sizeof(IEEE154_header_t));

      // size is  one for the length byte, minus two for the checksum
      pkt.len = mac_hdr->length - MAC_HEADER_SIZE - MAC_FOOTER_SIZE - sizeof(struct flow_id);
      // add one for the dispatch byte.
      pkt.data = ser_data + 1 + sizeof(IEEE154_header_t) + sizeof(struct flow_id);
#else 
      // size is  one for the length byte, minus two for the checksum
      pkt.len = mac_hdr->length - MAC_HEADER_SIZE - MAC_FOOTER_SIZE;
      // add one for the dispatch byte.
      pkt.data = ser_data + 1 + sizeof(IEEE154_header_t);
#endif // DBG_TRACK_FLOWS

      // for some reason these are little endian so we don't do any conversion.
      pkt.src = mac_hdr->src;
      pkt.dst = mac_hdr->dest;
#else
      mac_hdr = (serial_header_t *)(ser_data + 1);

      if (mac_hdr->type != 0) {
        goto discard_packet;
      }

#ifdef DBG_TRACK_FLOWS
      fl_id = (struct flow_id *)(ser_data + 1 + sizeof(serial_header_t));
      pkt.len = mac_hdr->length - sizeof(struct flow_id);
      pkt.data = ser_data + 1 + sizeof(serial_header_t) + sizeof(struct flow_id);
#else
      pkt.len = mac_hdr->length;;
      pkt.data = ser_data + 1 + sizeof(serial_header_t);
#endif // DBG_TRACK_FLOWS

      // except in serial packets, they __are__ little endian...
      pkt.src = ntohs(mac_hdr->src);
      pkt.dst = ntohs(mac_hdr->dest);
#endif

      debug("serial_input: read 0x%x bytes\n", ser_len);

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

        if (hasFrag1Header(&pkt)) {
          if (unpackHeaders(&pkt, &u_info,
                            (uint8_t *)&msg->hdr, recon->size) == NULL) goto discard_packet;
          amount_here = pkt.len - (u_info.payload_start - pkt.data);
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
        u_info.rih = NULL;
        msg = (struct split_ip_msg *)shortMsg;
        if (unpackHeaders(&pkt, &u_info,
                          (uint8_t *)&msg->hdr, INET_MTU) == NULL) goto discard_packet;
        if (ntohs(msg->hdr.plen) > INET_MTU - sizeof(struct ip6_hdr)) goto discard_packet;

        msg->metadata.sender = pkt.src;
        if (u_info.rih != NULL)
          info("Has a rinstall_header for src 0x%x with match: 0x%x\n", 
               pkt.src, ntohs(u_info.rih->match.dest));;

        ip_memcpy(u_info.header_end, u_info.payload_start, ntohs(msg->hdr.plen));
#ifdef DBG_TRACK_FLOWS
        ip_memcpy(&msg->id, fl_id, sizeof(struct flow_id));
#endif

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

void print_stats() {
  printf("Up since %s", ctime(&stats.boot_time));
  printf("  receive  packets: %lu fragments: %lu bytes: %lu\n",
         stats.tx_pkts, stats.tx_frags, stats.tx_bytes);
  printf("  transmit packets: %lu fragments: %lu bytes: %lu\n",
         stats.rx_pkts, stats.rx_frags, stats.rx_bytes);
  printf("  forward  packets: %lu\n", stats.fw_pkts);
}

int eval_cmd(char *cmd) {
  char arg[1024];
  int int_arg;
  switch (cmd[0]) {
  case 'c':
    config_print(&driver_config);
    return 0;
  case 'd':
    if (sscanf(cmd, "d %s\n", arg) == 1) {
      nw_print_dotfile(arg);
    } else {
      printf("error: include a filename!\n");
    }
    return 0;
  case 'i':
    if (sscanf(cmd, "i %i\n", &int_arg) == 1) {
      info("invalidating node 0x%x\n", int_arg);
      nw_inval_node(int_arg);
    }
    return 0;
  case 'l':
    nw_print_links();
    return 0;
  case 'p':
    nw_print_routes();
    return 0;
  case 's':
    print_stats();
    return 0;
  case 't':
    nw_test_routes();
    return 0;
  case 'v':
    if (sscanf(cmd, "v %s\n", arg) == 1) {
      int i;
      for (i = 0; i < 5; i++) {
        if (strcmp(log_names[i], arg) == 0) {
          printf("setting verbosity to %s\n", log_names[i]);
          log_setlevel(i);
        }
      }
    }
    return 0;
  case 'h':
  default:
    printf("ip-driver console\n");
    printf("  c: print configuration info\n");
    printf("  d <dotfile>: print dot-file of topology\n");
    printf("  i <nodeid>: invalidate a router\n");
    printf("  l: print link detail\n");
    printf("  p: print routes\n");
    printf("  t: recalculate routes\n");
    printf("  v {DEBUG INFO WARN ERROR FATAL}: set verbosity\n");
    printf("  s: print statistics\n");
    printf("\n");
    printf("  h: print this help\n");           
  }

  return 0;
}

/* shifts data between the serial port and the tun interface */
int serial_tunnel(int tun_fd) {
  char cmd_buf[2][1024], *cmd_cur;
  int cur_buf = 0;
  fd_set fs;
  int maxfd = 0;
  time_t last_aging, current_time;
  time(&last_aging);
#ifndef SIM
  int pan_fd = serial_source_fd(ser_src);
#else
  int pan_fd = sf_fd;
#endif
  cmd_cur = cmd_buf[0];

  /* disable input buffering on stdin since we're going to accumulate
     the input outselves, and don't want to block */
  if (isatty(fileno(stdin))) {
    struct termios tio;
    /* disable it on the fd */
    if (tcgetattr(fileno(stdin), &tio))
      return -1;
    tio.c_lflag &= ~ICANON;
    if (tcsetattr(fileno(stdin), TCSANOW, &tio))
      return -1;
    /* and also in libc */
    setbuf(stdin, NULL);
  }

  while (1) {
    FD_ZERO(&fs);
    FD_SET(tun_fd, &fs);
    FD_SET(pan_fd, &fs);

    maxfd = max(tun_fd, pan_fd);
    if (isatty(fileno(stdin))) {
      FD_SET(fileno(stdin), &fs);
      maxfd = max(fileno(stdin), maxfd);
    }
    if (radvd_fd >= 0) {
      FD_SET(radvd_fd, &fs);
      maxfd = max(radvd_fd, maxfd);
    }

    if (select(maxfd + 1, &fs, NULL, NULL, NULL) < 0)
      continue;

    
    /* data available on tunnel device */
    if (FD_ISSET(tun_fd, &fs))
      while(tun_input());

    if (FD_ISSET(pan_fd, &fs))
      while(serial_input());
    
    if (FD_ISSET(fileno(stdin), &fs)) {
      *cmd_cur++ = getc(stdin);
      if (*(cmd_cur - 1) == '\n' || 
          cmd_cur - cmd_buf[cur_buf] == 1024) {
        *cmd_cur = '\0';
        if (cmd_cur == cmd_buf[cur_buf] + 1) {
          eval_cmd(cmd_buf[(cur_buf + 1) % 2]);
        } else {
          eval_cmd(cmd_buf[cur_buf]);
          cur_buf = (cur_buf + 1) % 2;
        }
        cmd_cur = cmd_buf[cur_buf];
      }
    }
    
    if (radvd_fd >= 0 && FD_ISSET(radvd_fd, &fs)) {
      radvd_process();
    }

#ifndef SIM
/*     if (tcdrain(pan_fd) < 0) { */
/*       fatal("tcdrain error: %i\n", errno); */
/*       exit(3); */
/*     } */
#endif

    /* end of data available */
    time(&current_time);
    if (current_time > last_aging + (FRAG_EXPIRE_TIME / 1024)) {
      last_aging = current_time;
      age_reconstructions();
    }
  }

  return 0;
}

#ifdef DBG_TRACK_FLOWS
void truncate_dbg() {
  ftruncate(fileno(dbg_file), 0);
}
#endif

int main(int argc, char **argv) {
  int i, c;

  time(&stats.boot_time);

  log_init();
  while ((c = getopt(argc, argv, "c:")) != -1) {
    switch (c) {
    case 'c':
      def_configfile = optarg;
      break;
    default:
      fatal("Invalid command line argument.\n");
      exit(1);
    }
  }

  if (argc - optind != 2) {
#ifndef SIM
    fatal("usage: %s [-c config] <device> <rate>\n", argv[0]);
#else
    fatal("usage: %s [-c config] <host> <port>\n", argv[0]);
#endif
    exit(2);
  }
    
#ifdef DBG_TRACK_FLOWS
  dbg_file = fopen("dbg.txt", "w");
  if (dbg_file == NULL) {
    perror("main: opening dbg file:");
    exit(1);
  }
  signal(SIGUSR2, truncate_dbg);
#endif

  if (config_parse(def_configfile, &driver_config) != 0) {
    fatal ("config parse of %s failed!\n", def_configfile);
    exit(1);
  }
  globalPrefix = 1;
  memcpy(&__my_address, &driver_config.router_addr, sizeof(struct in6_addr));
  
  /* create the tunnel device */
  dev[0] = 0;
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
#ifndef SIM
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

  info("Press 'h' for help\n");

  routing_init(&driver_config, dev);
#ifndef SIM
  configure_reboot();
#endif

  /* start tunneling */
  serial_tunnel(tun_fd);

  /* clean up */
  // close_serial_source(ser_src);
  // close(ser_fd);
  tun_close(tun_fd, dev);
  return 0;
}
