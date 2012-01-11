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
/**
 * DHCP v6 Client implementation for TinyOS
 *
 * Implements a simple subset of RFC3315 DHCP for stateful address
 * configuration.  This protocol engine solicits on-link DHCP servers
 * or relay agents, and then attempts to obtain permanent (IA_NA)
 * addresses from them.  After an address is acquired, it will renew
 * it using the parameters contained in the Identity Association
 * binding; if the lease expires, it will revoke the address using the
 * IPAddress interface.  At that point all components should stop
 * using that address as it is no longer valid.
 *
 * @author Stephen Dawson-Haggerty <stevedh@eecs.berkeley.edu>
 */
#include "dhcp6.h"

module Dhcp6ClientP {
  provides {
    interface Dhcp6Info;
    interface StdControl;
  }
  uses {
    interface UDP;
    interface Timer<TMilli>;
    interface Random;
    interface IPAddress;
    interface Ieee154Address;
    interface Leds;
  }
} implementation {

  int m_state;

  // txid: current transaction id
  // t1: time after which to renew the current IA binding from the original server
  // t2: time after which to renew using any available server
  // m_time: timeout clock used for state machine transitions
  // valid_lifetime: valid life of address obtained 
  uint32_t m_txid, t1, t2, m_time = 0, valid_lifetime = 0;

  // the dhcp6 server we are currently interacting with
  struct sockaddr_in6 m_srv_addr;

  // DUID of the server we're talking and have obtained the binding from
  bool m_serverid_valid = FALSE;
  char m_serverid[DH6_MAX_DUIDLEN];

  // weather to send unicast messages once we've picked a server from
  // ADVERTIZE messages
  bool m_unicast = TRUE;

  enum {
    // my IAID for all transactions
    IAID = 1,
    VALID_WAIT = 0xff,
    
    // how long to send requests before hopping back to SOLICIT
    REQUEST_TIMEOUT = 120,

    TIMER_PERIOD = 15,
  };
  
  command error_t StdControl.start() {
    m_state = DH6_SOLICIT;
    call UDP.bind(DH6PORT_DOWNSTREAM);
    // call Timer.startPeriodic(1024 * TIMER_PERIOD);
    call Timer.startOneShot((1024L * TIMER_PERIOD) % (call Random.rand16()));
    return SUCCESS;
  }
  
  command error_t StdControl.stop() { 
    call Timer.stop();
    valid_lifetime = 0;
    call UDP.bind(0);
    call IPAddress.removeAddress();
    return SUCCESS;
  }

  void setup(struct dh6_request *req, int type) {
    ieee154_laddr_t eui64;
    m_txid = call Random.rand32() & 0xffffff;

    eui64 = call Ieee154Address.getExtAddr();
    req->dh6_hdr.dh6_type_txid = htonl((((uint32_t)type << 24)) | m_txid);
    req->dh6_id.type = htons(DH6OPT_CLIENTID);
    req->dh6_id.len = htons(12);
    req->dh6_id.duid_ll.duid_type = htons(3);
    req->dh6_id.duid_ll.hw_type = htons(HWTYPE_EUI64);
    memcpy(req->dh6_id.duid_ll.eui64, eui64.data, 8);
  }

  void sendSolicit() {
    struct dh6_request sol;
    // create a solicit message
    setup(&sol, DH6_SOLICIT);

    // these always go to the ALLAGENT multicast group, so overwrite
    // whoever we might have been corresponding with.
    inet_pton6(DH6ADDR_ALLAGENT, &m_srv_addr.sin6_addr);
    m_srv_addr.sin6_port = htons(DH6PORT_UPSTREAM);

    call Leds.led0Toggle();
    call UDP.sendto(&m_srv_addr, &sol, sizeof(struct dh6_solicit));
  }

  void sendRequest() {
    char msg[sizeof(struct dh6_request) + sizeof(m_serverid)];
    struct dh6_request *req = (struct dh6_request *)msg;
    int len = sizeof(struct dh6_request);
    struct dh6_opt_header *hdr = (struct dh6_opt_header *)m_serverid;

    setup(req, DH6_REQUEST);

    req->dh6_ia.type = ntohs(DH6OPT_IA_NA);
    req->dh6_ia.len = ntohs(12);
    req->dh6_ia.iaid = ntohl(IAID);
    req->dh6_ia.t1 = 0xffffffff;
    req->dh6_ia.t2 = 0xffffffff;
    
    memcpy(msg + sizeof(struct dh6_request), 
           m_serverid,
           sizeof(m_serverid));

    if (!m_serverid_valid) {
      return;
    }
    
    if (ntohs(hdr->len) > sizeof(m_serverid)) {
      return;
    }

    len += ntohs(hdr->len) + sizeof(struct dh6_opt_header);

    call UDP.sendto(&m_srv_addr, msg, len);
  }

  void sendRenew() {
    char msg[sizeof(struct dh6_request) + 
             sizeof(m_serverid) +
             sizeof(struct dh6_iaaddr)];
    struct dh6_request *req = (struct dh6_request *)msg;
    int len;
    struct dh6_opt_header *srvid = (struct dh6_opt_header *)m_serverid;
    struct dh6_iaaddr *iaaddr = (struct dh6_iaaddr *)(req + 1);
    void *msg_srvid = (iaaddr + 1);

    // request and server DUID
    len = sizeof(struct dh6_request) + 
      sizeof(struct dh6_opt_header) + ntohs(srvid->len);
    setup(req, DH6_RENEW);

    req->dh6_ia.type = ntohs(DH6OPT_IA_NA);
    req->dh6_ia.len = ntohs(12 + sizeof(struct dh6_iaaddr));
    req->dh6_ia.iaid = ntohl(IAID);
    req->dh6_ia.t1 = t1;
    req->dh6_ia.t2 = t2;
    
    len += sizeof(struct dh6_iaaddr);
    iaaddr->type = htons(5);
    iaaddr->len = htons(24);
    call IPAddress.getGlobalAddr(&iaaddr->addr);
    iaaddr->preferred_lifetime = htonl(3600); //preferred_lifetime);
    iaaddr->valid_lifetime = htonl(7200);//preferred_lifetime);

    memcpy(msg_srvid, m_serverid, sizeof(m_serverid));
    call UDP.sendto(&m_srv_addr, msg, len);
  }

  event void Timer.fired() {
    // state machine transition timeouts
    if (!call Timer.isRunning())
      call Timer.startPeriodic(1024L * TIMER_PERIOD);

    switch (m_state) {
    case DH6_SOLICIT:
      sendSolicit();
      break;
    case DH6_REQUEST:
      if (m_time > REQUEST_TIMEOUT) {
        m_state = DH6_SOLICIT;
        m_time = 0;
        sendSolicit();
      } else {
        sendRequest();
      }
      break;
    case DH6_RENEW:
      if (m_time > 0 && m_time > ntohl(t2)) {
        // maybe pick a different server...
        m_state = DH6_SOLICIT;
        m_time = 0;
        sendSolicit();
      } else {
        sendRenew();
      }
      break;
    case VALID_WAIT:
      if (m_time > 0 && m_time > ntohl(t1)) {
        m_state = DH6_RENEW;
      }
      break;
    }
    if (m_time > 0) 
      m_time += TIMER_PERIOD;

    // address expirations are separate from the state machine
    // transitions
    if (valid_lifetime > TIMER_PERIOD && 
        valid_lifetime <= TIMER_PERIOD * 2) {
      // lease really expired
      m_state = DH6_SOLICIT;
      call IPAddress.removeAddress();
      valid_lifetime = 0;
    } 

    if (valid_lifetime > 0) 
      valid_lifetime -= TIMER_PERIOD;
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

  event void UDP.recvfrom(struct sockaddr_in6 *src, void *payload, 
                          uint16_t len, struct ip6_metadata *meta) {
    struct dh6_header *hdr = payload;
    struct dh6_opt_header *opt;
    void *id;
    uint16_t type = ntohl(hdr->dh6_type_txid) >> 24;
    uint32_t txid = ntohl(hdr->dh6_type_txid) & 0xffffff;

    if (txid != m_txid) 
      return;      

    switch (m_state) {
    case DH6_SOLICIT:
      switch (type) {
      case DH6_ADVERTISE:
        opt = id = findOption(hdr + 1, len - sizeof(struct dh6_header), 
                              DH6OPT_SERVERID);
        if (id) {
          // save the server DUID for use in reply messages and start
          // requesting an address.
          if (ntohs(opt->len) + sizeof(struct dh6_opt_header) < sizeof(m_serverid)) {
            m_serverid_valid = TRUE;
            memcpy(m_serverid, id, ntohs(opt->len) + 
                   sizeof(struct dh6_opt_header));
            // we can unicast to this guy now
            // memcpy(&m_srv_addr, src, sizeof(struct sockaddr_in6));
            m_time = 1;
            m_state = DH6_REQUEST;
            if (m_unicast) 
              memcpy(&m_srv_addr, src, sizeof(struct sockaddr_in6));
            // don't wait a long while before we send our request
            if (!call Timer.isOneShot ())
                call Timer.startOneShot(1024L);
          }
        }
      }
      break;
    case DH6_REQUEST:
    case DH6_RENEW:
      call Leds.led1Toggle();
      if (type != DH6_REPLY) return;
      opt = id = findOption(hdr + 1, len - sizeof(struct dh6_header),
                            DH6OPT_SERVERID);
      if (id) {
        // check that the serverid is the one we asked for
        if (memcmp(m_serverid, id, ntohs(opt->len) +
                   sizeof(struct dh6_opt_header)) != 0) 
          return;
        // TODO : check client id
      }
      opt = id = findOption(hdr + 1, len - sizeof(struct dh6_header), DH6OPT_IA_NA);
      if (id) {
        struct dh6_ia *ia = id;
        struct dh6_status *status;
        void *addr_opt;
        // we got an IA_NA block back
        if (ntohl(ia->iaid) != IAID)
          return;

        // see if there's an error code
        status = findOption(ia + 1, ntohs(ia->len) + sizeof(struct dh6_opt_header) - sizeof(struct dh6_ia), 13);
        if (status) {
          if (status->code != htons(0)) {
            if (m_state == DH6_RENEW) {
              m_state = DH6_REQUEST;
              m_time  = 1;
            } else {
              m_state = DH6_SOLICIT;
              m_time  = 0;
            }
            call IPAddress.removeAddress();
            call Timer.startOneShot (0); // attempt immediate recovery
            return;
          }
        }

        // otherwise, hopefully there's an address
        addr_opt = findOption(ia + 1, ntohs(ia->len) + sizeof(struct dh6_opt_header) - sizeof(struct dh6_ia), 5);
        if (addr_opt) {
          // got an address... save it and wait for it to expire
          struct dh6_iaaddr *addr = addr_opt;
          if (m_state != DH6_RENEW) // only set it if it changed
            call IPAddress.setAddress(&addr->addr);
          t1 = ia->t1;
          t2 = ia->t2;
          m_time = 1;
          valid_lifetime = ntohl(addr->valid_lifetime);
          m_state = VALID_WAIT;
          call Leds.led2Toggle();
        }
      }
      break;
    }
  }

  command int Dhcp6Info.getTimers(struct dh6_timers *t) {
    t->iaid = IAID;
    t->valid_lifetime = valid_lifetime;
    t->clock = m_time;
    t->t1 = ntohl(t1);
    t->t2 = ntohl(t2);
    return 0;
  }

  command int Dhcp6Info.getDuid(uint8_t *buf, int len) {
    if (m_serverid_valid) {
      struct dh6_opt_header *opt = (struct dh6_opt_header *)m_serverid;
      if (ntohs(opt->len) < len) {
        memcpy(buf, m_serverid + sizeof(struct dh6_opt_header),
               ntohs(opt->len));
        return ntohs(opt->len);
      }
    }
    return -1;
  }

  command void Dhcp6Info.useUnicast(bool yes) {
    m_unicast = yes;
  }

  event void IPAddress.changed(bool global_valid) {}
  event void Ieee154Address.changed() {}

}
