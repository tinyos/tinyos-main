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

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <net/if.h>

#include <6lowpan.h>
#include <lib6lowpan.h>
#include "routing.h"
#include "nwstate.h"
#include "logging.h"
#include "config.h"

static hw_addr_t my_short_addr;
extern struct in6_addr  __my_address;

char proxy_dev[IFNAMSIZ], tun_dev[IFNAMSIZ];

/*
 * Call to setup routing tables.
 *
 */
uint8_t routing_init(struct config *c, char *tun_name) {
  nw_init();
  my_short_addr = ntohs(__my_address.s6_addr16[7]);
  strncpy(proxy_dev, c->proxy_dev, IFNAMSIZ);
  strncpy(tun_dev, tun_name, IFNAMSIZ);
/*   nl_fd = socket(AF_NETLINK, SOCK_RAW, protocol); */
/*   if (nl_fd < 0)  */
/*     return -1; */

  return 0;
}

/*
 * @returns: truth value indicating if the destination of the packet
 * is a single hop, and requires no source route.
 */
uint8_t routing_is_onehop(struct split_ip_msg *msg) {
  path_t *path;
  uint8_t ret = ROUTE_NO_ROUTE;

  if (cmpPfx(msg->hdr.ip6_dst.s6_addr, multicast_prefix))
    return ROUTE_ONEHOP;

  if (msg->hdr.nxt_hdr == NXTHDR_SOURCE) {
    debug("routing_is_onehop: Source header\n");
    return ROUTE_SOURCE;
  }

  path = nw_get_route(my_short_addr, ntohs(msg->hdr.ip6_dst.s6_addr16[7]));
  
  if (path != NULL) {
    if (path->length == 1)
      ret = ROUTE_ONEHOP;
    else
      ret = ROUTE_MHOP;
  }
  debug("routing_is_onehop: 0x%x\n", ret);
  nw_free_path(path);
  return ret;
}

/*
 * Identical to routing_insert_route, except allows for a detour route
 */
/*uint8_t routing_insert_route_indirect(struct split_ip_msg *orig, ip6_addr_t detour) {
  int offset = 0;
  path_t *path = nw_get_route(my_short_addr, l2fromIP(detour));
  path_t *path_second = nw_get_route(l2fromIP(detour), l2fromIP(orig->hdr.dst_addr));
  path_t *i;
  struct generic_header *g_hdr = (struct generic_header *)malloc(sizeof(struct generic_header));
  struct source_header *sh;

  debug("routing_insert_route_indirect len1: 0x%x, len2: 0x%x\n", path->length, path_second->length);

  if (ntoh16(orig->hdr.plen) + sizeof(struct source_header) + ((path->length + path_second->length) * sizeof(uint16_t)) + sizeof(struct ip6_hdr) > INET_MTU) {
    warn("packet plus source header too long\n");
    return 1;
  }

  sh = (struct source_header *)malloc(sizeof(struct source_header) + (path->length + path_second->length)*sizeof(uint16_t));
  if (sh == NULL || g_hdr == NULL) return 1;

  sh->nxt_hdr = orig->hdr.nxt_hdr;
  sh->len = sizeof(struct source_header) + ((path->length + path_second->length) * sizeof(uint16_t));
  sh->dispatch = IP_EXT_SOURCE_DISPATCH;
  sh->current = 0;
  orig->hdr.nxt_hdr = NXTHDR_SOURCE;

  fprintf(stderr, "to 0x%x [%i]: ", noths(orig->hdr.ip6_dst.s6_addr16[7]), path->length + path_second->length);
  for (i = path; i != NULL; i = i->next) {
    fprintf(stderr, "0x%x ", i->node);
    sh->hops[offset++] = hton16(i->node);
  }
  for (i = path_second; i != NULL; i = i->next) {
    fprintf(stderr, "0x%x ", i->node);
    sh->hops[offset++] = hton16(i->node);
  }

  fprintf(stderr, "\n");

  orig->hdr.plen = hton16(ntoh16(orig->hdr.plen) + sh->len);

  g_hdr->payload_malloced = 1;
  g_hdr->len = sh->len;
  g_hdr->hdr.sh = sh;
  g_hdr->next = orig->headers;
  orig->headers = g_hdr;

  nw_free_path(path);
  nw_free_path(path_second);

  return 0;
}
*/

/*
 * Copys the IP message at orig to the empty one at ret, inserting
 * necessary routing information.
 */
uint8_t routing_insert_route(struct split_ip_msg *orig) {
  int offset = 0;
  path_t *path = nw_get_route(my_short_addr, ntohs(orig->hdr.ip6_dst.s6_addr16[7]));
  path_t *i;
  struct generic_header *g_hdr = (struct generic_header *)malloc(sizeof(struct generic_header));
  struct source_header *sh;

  if (g_hdr == NULL || path == NULL) {
    if (g_hdr) free(g_hdr);
    if (path) nw_free_path(path);
    return 1;
  }
  if (path->length == 1) {
    free(g_hdr);
    nw_free_path(path);
    return 1;
  }
  debug("routing_insert_route len: 0x%x\n", path->length);

  // if the packet with the source route is longer then the buffer
  // we're putting it into, drop it.
  if (ntoh16(orig->hdr.plen) + sizeof(struct source_header) + 
      (path->length * sizeof(uint16_t)) + sizeof(struct ip6_hdr) > INET_MTU) {
    warn("packet plus source header too long\n");
    free(g_hdr);
    nw_free_path(path);
    return 1;
  }
  
  sh = (struct source_header *)malloc(sizeof(struct source_header) + path->length * sizeof(uint16_t));
  if (sh == NULL) {
    free (g_hdr);
    nw_free_path(path);
    return 1;
  }

  sh->nxt_hdr = orig->hdr.nxt_hdr;
  sh->len = sizeof(struct source_header) + (path->length * sizeof(uint16_t));
  sh->dispatch = IP_EXT_SOURCE_DISPATCH | IP_EXT_SOURCE_CONTROLLER;
  sh->current = 0;
  
  orig->hdr.nxt_hdr = NXTHDR_SOURCE;

  log_clear(LOGLVL_DEBUG, "to 0x%x [%i]: ", ntohs(orig->hdr.ip6_dst.s6_addr16[7]), path->length);
  for (i = path; i != NULL; i = i->next) {
    log_clear(LOGLVL_DEBUG, "0x%x ", i->node);
    sh->hops[offset++] = hton16(i->node);
  }
  log_clear(LOGLVL_DEBUG, "\n");

  orig->hdr.plen = hton16(ntoh16(orig->hdr.plen) + sh->len);

  g_hdr->payload_malloced = 1;
  g_hdr->len = sh->len;
  g_hdr->hdr.sh = sh;
  g_hdr->next = orig->headers;
  orig->headers = g_hdr;

  nw_free_path(path);

  return 0;

}

/*
 * Returns the address of the next router this packet should be send to.
 */
hw_addr_t routing_get_nexthop(struct split_ip_msg *msg) {
  hw_addr_t ret = 0xffff;;
  path_t * path;
  if (cmpPfx(msg->hdr.ip6_dst.s6_addr, multicast_prefix))
    return ret;

  // If it's source routed, just grab the next hop out of the header 
  if (msg->hdr.nxt_hdr == NXTHDR_SOURCE) {
    debug("routing_get_nexthop: src header\n"); 
    return ntoh16((msg->headers->hdr.sh->hops[msg->headers->hdr.sh->current]));
  }

  path = nw_get_route(my_short_addr, ntohs(msg->hdr.ip6_dst.s6_addr16[7]));

  if (path != NULL)
    ret = path->node;

  nw_free_path(path);

  return ret;
}

void routing_proc_msg(struct split_ip_msg *msg) {
  struct generic_header *g_hdr, **prev_hdr;
  uint8_t *prev_next, nxt_hdr = msg->hdr.nxt_hdr;
  int i;
  node_id_t reporter = ntohs(msg->hdr.ip6_src.s6_addr16[7]);

  prev_next = &msg->hdr.nxt_hdr;
  prev_hdr = &msg->headers;

  nw_report_node(reporter);
  for (g_hdr = msg->headers; g_hdr != NULL; g_hdr = g_hdr->next) {
    if (nxt_hdr == NXTHDR_TOPO) {
      // add the topology reports to the database 
      nw_unmark_links(reporter);
      for (i = 0; i < (g_hdr->len - sizeof(struct topology_header))/sizeof(struct topology_entry); i++) {
        //debug("topo neigh: 0x%x hop: %i qual: 0x%x\n", g_hdr->hdr.th->topo[i].hwaddr,
             // g_hdr->hdr.th->topo[i].hops, g_hdr->hdr.th->topo[i].link);
        nw_add_incr_edge(reporter, &g_hdr->hdr.th->topo[i]);
      }
      nw_clear_unmarked(reporter);
      // remove the topology header
      *prev_next = g_hdr->hdr.ext->nxt_hdr;
      *prev_hdr = g_hdr->next;
      if (g_hdr->payload_malloced) free(g_hdr->hdr.data);
      msg->hdr.plen = hton16(ntoh16(msg->hdr.plen) - g_hdr->len);
      free(g_hdr);
      return;
    } else {
      nxt_hdr = g_hdr->hdr.ext->nxt_hdr;
      prev_next = &g_hdr->hdr.ext->nxt_hdr;
      prev_hdr = &g_hdr->next;
    }
  }
}


void routing_add_table_entry(node_id_t id) {
  /* static const char* route_add_fmt = "ip -6 route add %x%02x:%x%02x:%x%02x:%x%02x:%x%02x:%x%02x:%x%02x:%x%02x/128 dev %s"; */
  /* static const char* route_proxy_fmt = "ip -6 neigh add proxy %x%02x:%x%02x:%x%02x:%x%02x:%x%02x:%x%02x:%x%02x:%x%02x dev %s"; */
 
}
