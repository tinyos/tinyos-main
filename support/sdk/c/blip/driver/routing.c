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
#include <arpa/inet.h>
#include <sys/select.h>
#include <net/route.h>
#include <sys/ioctl.h>
#include <sys/time.h>

#include <lib6lowpan/6lowpan.h>
#include <lib6lowpan/lib6lowpan.h>
#include "routing.h"
#include "nwstate.h"
#include "logging.h"
#include "config.h"
#include "mcast.h"
#include "netlink.h"

static ieee154_saddr_t my_short_addr;
static uint16_t current_seqno;
extern struct in6_addr  __my_address;

char proxy_dev[IFNAMSIZ], tun_dev[IFNAMSIZ];
int mcast_sock;

char report_buf[ROUTMSGSIZ];

/*
 * Call to setup routing tables.
 *
 */
int routing_init(struct config *c, char *tun_name) {
  FILE *fd;
  char buf[256];
  my_short_addr = ntohs(__my_address.s6_addr16[7]);
  strncpy(proxy_dev, c->proxy_dev, IFNAMSIZ);
  strncpy(tun_dev, tun_name, IFNAMSIZ);

  // set up the network state data structures
  nw_init();

  // start a netlink session to the kernel
  nl_init();

  mcast_sock = mcast_start(proxy_dev);;

  if ((fd = fopen("/proc/sys/net/ipv6/conf/all/forwarding", "w")) == NULL) {
    log_fatal_perror("enable forwarding");
    return -1;
  }
  fprintf(fd, "1");
  fclose(fd);

  snprintf(buf, sizeof(buf), "/proc/sys/net/ipv6/conf/%s/proxy_ndp", proxy_dev);
  if ((fd = fopen(buf, "w")) == NULL) {
    warn("unable to enable IPv6 ND proxy on %s\n", proxy_dev);
  } else {
    fprintf(fd, "1");
    fclose(fd);
  }

  if ((fd = fopen("/var/run/ip-driver.seq", "r")) != NULL) {
    if (fscanf(fd, "%hi\n", &current_seqno) != 1) {
      current_seqno = 0;
    }
    fclose(fd);
  }

  return (mcast_sock >= 0) ? 0 : -1;
}

int routing_add_fds(fd_set *fds) {
  if (mcast_sock >=0) {
    FD_SET(mcast_sock, fds);
  }
  return mcast_sock;
}

int route_cmd(int cmd, struct in6_addr *dest, char *dev) {
  struct in6_rtmsg rt;
  memset((char *) &rt, 0, sizeof(struct in6_rtmsg));
  memcpy(&rt.rtmsg_dst, dest, sizeof(struct in6_addr));

  rt.rtmsg_flags = RTF_UP | RTF_HOST;
  rt.rtmsg_metric = 1;
  rt.rtmsg_dst_len = 128;
  rt.rtmsg_ifindex = if_nametoindex(dev);

  return ioctl(mcast_sock, cmd, &rt);
}        


int routing_process(fd_set *fds) {
  struct sockaddr_in6 from;
  char buf[ROUTMSGSIZ], *cur, printbuf[100];
  struct routing_message *rmsg;
  struct topology_header_package *th;
  int len;
  struct in6_addr addr;

  if (mcast_sock < 0 || !FD_ISSET(mcast_sock, fds)) return 0;

  len = mcast_recvfrom(&from, buf, sizeof(buf));
  rmsg = (struct routing_message *)buf;

  inet_ntop(AF_INET6, &from.sin6_addr, printbuf, sizeof(printbuf));
  debug("processing routing message from %s type %i\n", printbuf, rmsg->type);

  memset(&addr, 0, sizeof(struct in6_addr));
  memcpy(addr.s6_addr, __my_address.s6_addr, 8);

  switch (rmsg->type) {
  case RMSG_TOPOLOGY:
    cur = rmsg->data;
    len -= sizeof(struct routing_message);
    while (len > 0) {
      router_t *router;
      int header_len, i;
      node_id_t reporter;

      th = (struct topology_header_package *)cur;
      header_len = ntohs(th->len);
      reporter = ntohs(th->reporter);

      nw_unmark_links(reporter);
      for (i = 0; i < (header_len - sizeof(struct topology_header_package))/sizeof(struct topology_entry); i++) {

        nw_add_incr_edge(reporter, &th->topo[i]);

        router = nw_get_router(reporter);
        gettimeofday(&router->lastReport, NULL);
        
        if (router == NULL) continue;
        addr.s6_addr16[7] = htons(reporter);

        if (rmsg->source == __my_address.s6_addr16[7] && !router->isProxying) {
          // if I sent this report, make sure we are proxying for him
          info("Starting to proxy for 0x%x\n", reporter);

          if (route_cmd(SIOCADDRT, &addr, tun_dev) < 0) {
            log_fatal_perror("route_add");
          }

          nl_nd_add_proxy(&addr, proxy_dev);
          router->isProxying = TRUE;
        }
        if (rmsg->source != __my_address.s6_addr16[7] && router->isProxying) {
          info("Was proxying 0x%x, but he has moved\n", reporter);
          if (route_cmd(SIOCDELRT, &addr, tun_dev) < 0) {
            log_fatal_perror("route_del");
          }

          nl_nd_del_neigh(&addr, proxy_dev);
          router->isProxying = FALSE;
        }
      }
      nw_clear_unmarked(reporter);

      router = nw_get_router(ntohs(rmsg->source));
      if (router != NULL && !router->isController) {
        nw_add_controller(ntohs(rmsg->source));
      }
      
      cur += header_len;
      len -= header_len;
    }
    break;
  }
  return 0;
}

int routing_add_report(node_id_t reporter, struct tlv_hdr *tlv) {
  struct topology_header *th = (struct topology_header *)(tlv + 1);
  struct routing_message *rmsg;
  struct topology_header_package *pack;

  rmsg = (struct routing_message *)report_buf;
  pack = (struct topology_header_package *)&rmsg->data[0];

  memset(report_buf, 0, sizeof(report_buf));

  debug("routing_add_report: report from 0x%x seq: %i\n", reporter, th->seqno);

  rmsg->type = RMSG_TOPOLOGY;
  rmsg->source = __my_address.s6_addr16[7];
  pack->reporter = htons(reporter);
  pack->seqno = th->seqno;
  pack->len      = htons(tlv->len - 
                         sizeof(struct tlv_hdr) -
                         sizeof(struct topology_header) + 
                         sizeof(struct topology_header_package));

  memcpy(pack->topo, th->topo, tlv->len - sizeof(struct tlv_hdr) -
         sizeof(struct topology_header));
  
  mcast_send(report_buf, ntohs(pack->len) + sizeof(struct routing_message));

  return 0;
}


/*
 * @returns: truth value indicating if the destination of the packet
 * is a single hop, and requires no source route.
 */
int routing_is_onehop(struct split_ip_msg *msg) {
  path_t *path;
  int ret = ROUTE_NO_ROUTE;

  if (msg->hdr.ip6_dst.s6_addr[0] == 0xff &&
      (msg->hdr.ip6_dst.s6_addr[1] & 0xf) <= 0x2)
    return ROUTE_ONEHOP;


#if 0
  if (msg->hdr.nxt_hdr == NXTHDR_SOURCE) {
    debug("routing_is_onehop: Source header\n");
    return ROUTE_SOURCE;
  }
#endif

  path = nw_get_route(my_short_addr, ntohs(msg->hdr.ip6_dst.s6_addr16[7]));
  
  if (path != NULL) {
    if (path->isController) {
      ret = ROUTE_WORMHOLE;
    } else if (path->length == 1) {
      ret = ROUTE_ONEHOP;
    } else {
      ret = ROUTE_MHOP;
    }
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
 */
uint8_t routing_insert_route(struct split_ip_msg *orig) {
  int offset = 0;
  path_t *path = nw_get_route(my_short_addr, ntohs(orig->hdr.ip6_dst.s6_addr16[7]));
  path_t *i;
  struct generic_header *g_hdr = (struct generic_header *)malloc(sizeof(struct generic_header));
  struct ip6_route *sh;

  if (g_hdr == NULL || path == NULL) {
    if (g_hdr) free(g_hdr);
    if (path) nw_free_path(path);
    return 1;
  }
#if 0
  if (path->length == 1) {
    free(g_hdr);
    nw_free_path(path);
    return 1;
  }
#endif

  debug("routing_insert_route len: 0x%x\n", path->length);

  // if the packet with the source route is longer then the buffer
  // we're putting it into, drop it.
  if (ntoh16(orig->hdr.plen) + sizeof(struct ip6_route) + 
      (path->length * sizeof(uint16_t)) + sizeof(struct ip6_hdr) > INET_MTU) {
    warn("packet plus source header too long\n");
    free(g_hdr);
    nw_free_path(path);
    return 1;
  }
  
  sh = (struct ip6_route *)malloc(sizeof(struct ip6_route) + path->length * sizeof(uint16_t));
  if (sh == NULL) {
    free (g_hdr);
    nw_free_path(path);
    return 1;
  }

  sh->nxt_hdr = orig->hdr.nxt_hdr;
  sh->len = sizeof(struct ip6_route) + (path->length * sizeof(uint16_t));
  sh->type = IP6ROUTE_FLAG_CONTROLLER | IP6ROUTE_TYPE_SOURCE;
  sh->segs_remain = path->length;
  
  orig->hdr.nxt_hdr = IPV6_ROUTING;

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
ieee154_saddr_t routing_get_nexthop(struct split_ip_msg *msg) {
  ieee154_saddr_t ret = 0xffff;;
  path_t * path;
  if (msg->hdr.ip6_dst.s6_addr[0] == 0xff &&
      (msg->hdr.ip6_dst.s6_addr[1] & 0xf) <= 0x2) {
    return ret;
  }

  // If it's source routed, just grab the next hop out of the header 
#if 0
  if (msg->hdr.nxt_hdr == NXTHDR_SOURCE) {
    debug("routing_get_nexthop: src header\n"); 
    return ntoh16((msg->headers->hdr.sh->hops[msg->headers->hdr.sh->current]));
  }
#endif

  path = nw_get_route(my_short_addr, ntohs(msg->hdr.ip6_dst.s6_addr16[7]));

  if (path != NULL)
    ret = path->node;

  nw_free_path(path);

  return ret;
}

uint16_t routing_get_seqno() {
  return current_seqno;
}

uint16_t routing_incr_seqno() {
  FILE *fd;
  ++current_seqno;
  if ((fd = fopen("/var/run/ip-driver.seq", "w")) != NULL) {
    fprintf(fd, "%hi\n", current_seqno);
    fclose(fd);
  }
  return current_seqno;
}
