/*
 * Copyright (c) 2008, 2009 The Regents of the University  of California.
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
 * radvd-wrapper.c
 * author: Stephen Dawson-Haggerty <stevedh@eecs.berkeley.edu>
 *
 * Alternate set of call points for the IPv6 router advertisement
 * daemon.  Using this interface the daemon may be integrated into
 * another program (like ip-driver).  radvd is distributed under a
 * BSD-like license.
 *
 * radvd_init() must be called to set up state for the specified
 *   interface.  If successful, it will return a file descriptor;
 *   radvd_process() must be called whenever there is pending data on
 *   this descriptor (ie, from a select() loop.)
 *
 * radvd has its own logging infrastructure; by default radvd_init()
 * sends that log to stderr and makes no attempt to integrate it with
 * whatever logging facilities may be availabile.  See radvd/log.c for
 * more.
 *
 * NB: radvd uses SIGALRM for its internal timer.  Thus, once
 * radvd_init() has been called, SIGALRM must not be used elsewhere in
 * the application.
 *
 */


#include "radvd-1.0/includes.h"
#include "radvd-1.0/radvd.h"
#include "radvd-1.0/pathnames.h"

#include "logging.h"
#include "config.h"

struct Interface *iface;
int sock;

void radvd_timer_handler(void *data) {
  struct Interface *iface = (struct Interface *) data;
  double next;

  dlog(LOG_DEBUG, 4, "timer_handler called for %s", iface->Name);

  send_ra(sock, iface, NULL);

  next = rand_between(iface->MinRtrAdvInterval, iface->MaxRtrAdvInterval); 

  if (iface->init_racount < MAX_INITIAL_RTR_ADVERTISEMENTS) {
    iface->init_racount++;
    next = min(MAX_INITIAL_RTR_ADVERT_INTERVAL, next);
  }

  set_timer(&iface->tm, next);
}

void radvd_reset_adverts(void) {
  if (iface->AdvSendAdvert) {
    /* send an initial advertisement */
    send_ra(sock, iface, NULL);
    
    iface->init_racount = 0;

    set_timer(&iface->tm,
              min(MAX_INITIAL_RTR_ADVERT_INTERVAL,
                  iface->MaxRtrAdvInterval));
  }
}


void radvd_kickoff_adverts(void) {
  init_timer(&iface->tm, radvd_timer_handler, (void *) iface);
  if (iface->AdvSendAdvert) {
    /* send an initial advertisement */
    send_ra(sock, iface, NULL);
    
    iface->init_racount++;

    set_timer(&iface->tm,
              min(MAX_INITIAL_RTR_ADVERT_INTERVAL,
                  iface->MaxRtrAdvInterval));
  }
}

void radvd_process() {
  unsigned char msg[MSG_SIZE];
  int len, hoplimit;
  struct sockaddr_in6 rcv_addr;
  struct in6_pktinfo *pkt_info = NULL;
  
  len = recv_rs_ra(sock, msg, &rcv_addr, &pkt_info, &hoplimit);
  if (len > 0)
    process(sock, iface, msg, len, 
            &rcv_addr, pkt_info, hoplimit);
  
}


/* Set up all the radvd internal stuff from our own configuration */
int radvd_init(char *ifname, struct config *c) {
  struct AdvPrefix *prefix;
  sigset_t oset, nset;


  if (log_open(L_STDERR, "radvd", NULL, -1) < 0) {
    error("log_open\n");
    return -1;
  }
  srand((unsigned int)time(NULL));
  info("starting radvd on device %s\n", ifname);

  sock = open_icmpv6_socket();
  if (sock < 0) {
    error("open_icmpv6_socket\n");
    return -1;
  }
  sigemptyset(&nset);
  sigaddset(&nset, SIGALRM);
  sigprocmask(SIG_UNBLOCK, &nset, &oset);
  if (sigismember(&oset, SIGALRM))
    flog(LOG_WARNING, "SIGALRM has been unblocked. Your startup environment might be wrong.");


  /* setup the radvd struct Interface to know about all our defaults */
  iface = malloc(sizeof(struct Interface));
  if (iface == NULL)
    return -1;

  iface_init_defaults(iface);
  strncpy(iface->Name, ifname, IFNAMSIZ-1);
  iface->Name[IFNAMSIZ-1] = '\0';

  iface->next = NULL;
  iface->AdvSendAdvert = 1;

  /* check the interface exists... this probably shouldn't fail */
  if (check_device(sock, iface) < 0) {
    error("check_device!\n");
    return -1;
  }
  
  if (setup_deviceinfo(sock, iface) < 0) {
    error("setup_deviceinfo\n");
    return -1;
  }
  if (check_iface(iface) < 0) {
    error("check_iface\n");
    return -1;
  }
  if (setup_linklocal_addr(sock, iface) < 0) {
    error("setup_linklocal_addr\n");
    return -1;
  }
  if (setup_allrouters_membership(sock, iface) < 0) {
    error("setup_allrouters_membership\n");
    return -1;
  }


  /* set up the prefix we're advertising from the config struct we get passed in. */
  prefix = malloc(sizeof(struct AdvPrefix));
  if (prefix == NULL)
    return -1;

  prefix_init_defaults(prefix);
  prefix->PrefixLen = 64;
  memcpy(&prefix->Prefix, c->router_addr.s6_addr, sizeof(struct in6_addr));
  prefix->next = NULL;

  iface->AdvPrefixList = prefix;


  // config_interface();
  radvd_kickoff_adverts();

  set_debuglevel(0);

  return sock;
}
