/*
 * Copyright (c) 2008-2010 The Regents of the University  of California.
 * All rights reserved."
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */
/*
 * DHCP v6 Relay Agent
 *
 * This agent forwards requests to the edge of the network.  It can
 * proxy the responses to SOLICIT messages so that there is less of a
 * reply implosion problem when bringing up a large network; doing so
 * is the default behavior.
 *
 * @author Stephen Dawson-Haggerty <stevedh@eecs.berkeley.edu>
 */

#include "blip_printf.h"
#include "dhcp6.h"

module Dhcp6RelayP {
  uses {
    interface UDP;
    interface Timer<TMilli> as AdvTimer;
    interface IPAddress;
    interface Ieee154Address;
    interface Boot;
    interface Random;
    interface Dhcp6Info;
  }
} implementation {
  bool m_alive = FALSE;
#define DHCP_PROXY_SOLICIT

#ifdef DHCP_PROXY_SOLICIT
  void *m_msg;
  int m_len;
#endif

  event void Boot.booted() {
    call UDP.bind(DH6PORT_UPSTREAM);
  }

  void *findOption(void *msg, int len, int type) {
    while (len >= sizeof(struct dh6_opt_header)) {
      struct dh6_opt_header *opt = msg;
      if (opt->type == htons(type)) {
        return msg;
      } else if (opt->len == 0) {
        break;
      } else {
        msg = 
          ((char*)msg) + ntohs(opt->len) + sizeof(struct dh6_opt_header);
        len -= ntohs(opt->len) + sizeof(struct dh6_opt_header);
      }
    }
    return NULL;
  }

#ifdef DHCP_PROXY_SOLICIT
  int setup(struct dh6_request *req, int type, uint32_t txid) {
    int len;
    req->dh6_hdr.dh6_type_txid = htonl((((uint32_t)type << 24)) | 
                                      (txid & 0xffffff));
    req->dh6_id.type = htons(DH6OPT_SERVERID);

    // we need to send back the DUID of our server
    len = call Dhcp6Info.getDuid((uint8_t *)&req->dh6_id.duid_ll, DH6_MAX_DUIDLEN);

    if (len < 0)
      return -1;

    req->dh6_id.len = htons(len);
    return len;
  }
#endif

  event void UDP.recvfrom(struct sockaddr_in6 *src, void *payload,
                          uint16_t len, struct ip6_metadata *meta) {
    struct dh6_header *hdr = payload;
    uint16_t type = ntohl(hdr->dh6_type_txid) >> 24;
    printf("relay agent RX!: %i\n", type);

    if (!m_alive) return;
    
#ifdef DHCP_PROXY_SOLICIT
    if (type == DH6_SOLICIT) {
      // send ADVERTISE
      if (!call AdvTimer.isRunning()) {
        struct dh6_request *req;
        struct sockaddr_in6 *m_src;
        m_msg = malloc(sizeof(struct dh6_request) + 
                       sizeof(struct sockaddr_in6) + DH6_MAX_DUIDLEN);
        if (!m_msg) return;

        req = (struct dh6_request *)(((char *)m_msg) + 
                                      sizeof(struct sockaddr_in6));
        m_src = (struct sockaddr_in6 *)m_msg;

        if ((m_len = setup(req, DH6_ADVERTISE, ntohl(hdr->dh6_type_txid) & 0xffffff )) < 0) {
          printf("DHCP Message construction faild\n");
          free(m_msg);
          return;
        }

        m_len += offsetof(struct dh6_request, dh6_id.duid_ll);

        memcpy(m_src, src, sizeof(struct sockaddr_in6));
        call AdvTimer.startOneShot(call Random.rand16() & 0x7);
      }
    } else
#endif // DHCP_PROXY_SOLICIT
    if (type == DH6_RELAY_REPLY) {
      struct dh6_relay_hdr *fw_hdr = payload;
      struct sockaddr_in6 peer;
      memcpy(&peer.sin6_addr, &fw_hdr->peer_addr, sizeof(struct in6_addr));
      // inet_pton6(DH6ADDR_ALLSERVER, &peer.sin6_addr);
      peer.sin6_port = htons(DH6PORT_DOWNSTREAM);
      
      if (ntohs(fw_hdr->opt_type) != 9) return;
      // if (ntohs(fw_hdr->opt_len) > len - sizeof(struct dh6_relay_hdr)) return;
      call UDP.sendto(&peer, (void *)(fw_hdr + 1), len - sizeof(struct dh6_relay_hdr));
    } else {
      // just forward it...
      struct dh6_relay_hdr fw_hdr;
      struct ip_iovec v[2];
      struct sockaddr_in6 srv_addr;

      inet_pton6(DH6ADDR_ALLSERVER, &srv_addr.sin6_addr);
      srv_addr.sin6_port = htons(DH6PORT_UPSTREAM);


      fw_hdr.type = DH6_RELAY_FORW;
      fw_hdr.hopcount = 1;
      call IPAddress.getGlobalAddr(&fw_hdr.link_addr);
      memcpy(&fw_hdr.peer_addr, &src->sin6_addr, sizeof(struct in6_addr));
      fw_hdr.opt_type = htons(9);
      fw_hdr.opt_len = htons(len);

      v[0].iov_base = (void *)&fw_hdr;
      v[0].iov_len = sizeof(fw_hdr);
      v[0].iov_next = &v[1];
      v[1].iov_base = payload;
      v[1].iov_len = len;
      v[1].iov_next = NULL;

      call UDP.sendtov(&srv_addr, v);
    }
  }

  event void AdvTimer.fired() {
    struct dh6_request *req;
    struct sockaddr_in6 *m_src;
    req = (struct dh6_request *)(((char *)m_msg) + 
                                 sizeof(struct sockaddr_in6));
    m_src = (struct sockaddr_in6 *)m_msg;
    
    call UDP.sendto(m_src, req, m_len);
    free(m_msg);
  }

  event void Ieee154Address.changed() {}
  event void IPAddress.changed(bool global_valid) {
    m_alive = global_valid;
  }
}
