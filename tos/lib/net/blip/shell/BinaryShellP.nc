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

#include <lib6lowpan/ip.h>
#include <IPDispatch.h>
#include <icmp6.h>
#include "Shell.h"
#include "BinaryShell.h"

module BinaryShellP {
  provides {
    interface BinaryCommand[uint16_t cmd_id];
  }
  uses {
    interface Boot;
    interface UDP;
    interface Leds;
    
    interface ICMPPing;
#if defined(PLATFORM_TELOSB) || defined(PLATFORM_EPIC)
    interface Counter<TMilli, uint32_t> as Uptime;
#endif

    // interface BinaryCommand as CmdEnumerate;
    interface BinaryCommand as CmdEcho;
    interface BinaryCommand as CmdPing6;
    interface BinaryCommand as CmdUptime;
    interface BinaryCommand as CmdIdent;

  }

} implementation {

  bool session_active;
  struct sockaddr_in6 session_endpoint;
  uint32_t boot_time;
  uint64_t uptime;
  uint8_t reply_buf[MAX_REPLY_LEN];

  event void Boot.booted() {
    atomic {
      uptime = 0;
#if defined(PLATFORM_TELOSB) || defined(PLATFORM_EPIC)
      boot_time = call Uptime.get();
#endif
    }
    call UDP.bind(2001);
  }


  command char *BinaryCommand.getBuffer[uint16_t cmd_id](int len) {
    if (len <= MAX_REPLY_LEN) return reply_buf;
    return NULL;
  }

  command void BinaryCommand.write[uint16_t cmd_id](nx_struct cmd_payload *data, int len) {
    data->id = cmd_id;
    call UDP.sendto(&session_endpoint, data, len);    
  }

  event void CmdEcho.dispatch(nx_struct cmd_payload *cmd, int len) {
    call CmdEcho.write(cmd, len);
  }

  event void CmdPing6.dispatch(nx_struct cmd_payload *cmd, int len) {
    nx_struct bshell_ping6 *ping = (nx_struct bshell_ping6 *)(cmd->data);

    call ICMPPing.ping((struct in6_addr *)ping->addr, ping->dt, ping->cnt);
  }

  event void CmdUptime.dispatch(nx_struct cmd_payload *cmd, int len) {
#if defined(PLATFORM_TELOSB) || defined(PLATFORM_EPIC)
    nx_struct cmd_payload        *p = (nx_struct cmd_payload *)reply_buf;
    nx_struct bshell_uptime      *u = (nx_struct bshell_uptime *)p->data;
    uint64_t tval = call Uptime.get();
    atomic {
      tval = (uptime + tval - boot_time) / 1024;
    }
    u->uptime_hi = tval >> 32;
    u->uptime_lo = tval & 0xffffffff;

    call CmdUptime.write(p,  sizeof(nx_struct cmd_payload) +
                         sizeof(nx_struct bshell_uptime));
#endif
  }

  event void CmdIdent.dispatch(nx_struct cmd_payload *cmd, int len) {
    nx_struct cmd_payload        *p = (nx_struct cmd_payload *)reply_buf;
    nx_struct bshell_ident       *i = (nx_struct bshell_ident *)p->data;
    memcpy(i->appname,  IDENT_APPNAME, 16);
    memcpy(i->username, IDENT_USERNAME, 16);
    memcpy(i->hostname, IDENT_HOSTNAME, 16);
    i->timestamp = IDENT_TIMESTAMP;
    call CmdIdent.write(p,sizeof(nx_struct cmd_payload) +
                        sizeof(nx_struct bshell_ident)); 
  }

  event void UDP.recvfrom(struct sockaddr_in6 *from, void *data, 
                          uint16_t len, struct ip6_metadata *meta) {
    nx_struct cmd_payload *payload = (nx_struct cmd_payload *)data;
    memcpy(&session_endpoint, from, sizeof(struct sockaddr_in6));
    signal BinaryCommand.dispatch[payload->id](payload, len);
  }

  event void ICMPPing.pingReply(struct in6_addr *source, struct icmp_stats *stats) {
    nx_struct cmd_payload        *p = (nx_struct cmd_payload *)reply_buf;
    nx_struct bshell_ping6_reply *r = (nx_struct bshell_ping6_reply   *)p->data;
    memcpy(r->addr, source, 16);
    r->seqno = stats->seq;
    r->dt    = stats->rtt;
    r->ttl   = stats->ttl;
    call BinaryCommand.write[BSHELL_PING6_REPLY](p, sizeof(nx_struct cmd_payload) +
                                                 sizeof(nx_struct bshell_ping6_reply));
  }

  event void ICMPPing.pingDone(uint16_t ping_rcv, uint16_t ping_n) {
    nx_struct cmd_payload        *p = (nx_struct cmd_payload *)reply_buf;
    nx_struct bshell_ping6_done  *d = (nx_struct bshell_ping6_done *)p->data;
    d->sent = ping_n;
    d->received = ping_rcv;
    call BinaryCommand.write[BSHELL_PING6_DONE](p, sizeof(nx_struct cmd_payload) +
                                                 sizeof(nx_struct bshell_ping6_done));
  }

#if  defined(PLATFORM_TELOSB) || defined(PLATFORM_EPIC)
  async event void Uptime.overflow() {
    atomic
      uptime += 0xffffffff;
  }
#endif

  default event void BinaryCommand.dispatch[uint16_t cmd_id](nx_struct cmd_payload *cmd, int len) {
    nx_struct cmd_payload      *p = (nx_struct cmd_payload *)reply_buf;
    nx_struct bshell_error     *e = (nx_struct bshell_error   *)p->data;
    e->code = BSHELL_ERROR_NOTFOUND;
    call BinaryCommand.write[BSHELL_ERROR](p, sizeof(nx_struct cmd_payload) +
                                           sizeof(nx_struct bshell_enumerate));
  }
}
