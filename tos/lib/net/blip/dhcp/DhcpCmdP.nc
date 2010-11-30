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

module DhcpCmdP {
  uses {
    interface ShellCommand;
    interface Dhcp6Info;
    interface IPAddress;
  }

} implementation {

#define TO_CHAR(X) (((X) < 10) ? ('0' + (X)) : ('a' + ((X) - 10)))
  
  event char *ShellCommand.eval(int argc, char **argv) {
#define LEN (MAX_REPLY_LEN - (cur - buf))
    char *cur, *buf = call ShellCommand.getBuffer(MAX_REPLY_LEN);
    struct in6_addr addr;
    struct dh6_timers timers;
    int duid_len;
    uint8_t duid[24];

    if (!(call IPAddress.getGlobalAddr(&addr)))
      return "no valid lease\n";

    call Dhcp6Info.getTimers(&timers);

    cur = buf;
    cur += snprintf(cur, LEN, "lease on ");
    cur += inet_ntop6(&addr, cur, LEN) - 1;
    *cur++ = '\n';
    cur += snprintf(cur, LEN, "iaid: %i valid: %li t1: %li t2: %li\n",
                   timers.iaid, timers.valid_lifetime, timers.t1, timers.t2);

    if ((duid_len = call Dhcp6Info.getDuid(duid, sizeof(duid))) > 0 &&
        LEN > duid_len * 3 + 6) {
      int i;
      cur += snprintf(cur, LEN, "duid: ");
      for (i = 0; i < duid_len; i++) {
        *cur++ = TO_CHAR(duid[i] >> 4);
        *cur++ = TO_CHAR(duid[i] & 0x0f);
        if (i < duid_len - 1)
          *cur++ = ':';
      }
      *cur++ = '\n';
    }
    *cur++ = '\0';
    return buf;
  }

  event void IPAddress.changed(bool valid) {}
}
