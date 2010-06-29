/*
 * Copyright (c) 2008 The Regents of the University  of California.
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

#include <ip.h>
#include <IPDispatch.h>
#include <ICMP.h>
#include "Shell.h"

module UDPShellP {
  provides {
    interface ShellCommand[uint8_t cmd_id];
    interface RegisterShellCommand[uint8_t cmd_id];
  }
  uses {
    interface Boot;
    interface UDP;
    interface Leds;
    
    interface ICMPPing;
#if defined(PLATFORM_TELOSB) || defined(PLATFORM_EPIC)
    interface Counter<TMilli, uint32_t> as Uptime;
#endif

  }

} implementation {

  bool session_active;
  struct sockaddr_in6 session_endpoint;
  uint32_t boot_time;
  uint64_t uptime;

  enum {
    N_EXTERNAL = uniqueCount("UDPSHELL_CLIENTCOUNT"),
  };

  // and corresponding indeces
  enum {
    N_BUILTINS = 5,
    // the maximum number of arguments a command can take
    N_ARGS = 10,
    CMD_HELP = 0,
    CMD_ECHO = 1,
    CMD_PING6 = 2,
    CMD_TRACERT6 = 3,

    CMD_NO_CMD = 0xfe,
    CMDNAMSIZ = 10,
  };
  
  struct cmd_name {
    uint8_t c_len;
    char c_name[CMDNAMSIZ];
  };
  struct cmd_builtin {
    void (*action)(int, char **);
  };

  struct cmd_name externals[N_EXTERNAL];


  event void Boot.booted() {
    int i;
    atomic {
      uptime = 0;
#if defined(PLATFORM_TELOSB) || defined(PLATFORM_EPIC)
      boot_time = call Uptime.get();
#endif
    }
    for (i = 0; i < N_EXTERNAL; i++) {
      externals[i].c_name[CMDNAMSIZ-1] = '\0';
      strncpy(externals[i].c_name, signal RegisterShellCommand.getCommandName[i](), CMDNAMSIZ);
      externals[i].c_len = strlen(externals[i].c_name);
    }
    call UDP.bind(2000);
  }


#define DEREF(X)  #X
#define QUOTE(X)  DEREF(X)
  char reply_buf[MAX_REPLY_LEN];
  char *help_str = "sdsh-0.9\tbuiltins: [help, echo, ping6, uptime, ident]\n";
  const char *ping_fmt = " icmp_seq=%i ttl=%i time=%i ms\n";
  const char *ping_summary = "%i packets transmitted, %i received\n";
  char *ident_string = "\t[app: "
    IDENT_APPNAME "]\n\t[user: " IDENT_USERNAME "]\n\t[host: " IDENT_HOSTNAME
    "]\n\t[time: " QUOTE(IDENT_TIMESTAMP) "]\n";
  

  void action_help(int argc, char **argv) {
    int i = 0;
    char *pos = reply_buf;
    call UDP.sendto(&session_endpoint, help_str, strlen(help_str));
    if (N_EXTERNAL > 0) {
      strcpy(pos, "\t\t[");
      pos += 3;
      for (i = 0; i < N_EXTERNAL; i++) {
        if (externals[i].c_len + 4 < MAX_REPLY_LEN - (pos - reply_buf)) {
          memcpy(pos, externals[i].c_name, externals[i].c_len);
          pos += externals[i].c_len;
          if (i < N_EXTERNAL-1) {
            pos[0] = ',';
            pos[1] = ' ';
            pos += 2;
          } 
        } else {
          pos[0] = '.';
          pos[1] = '.';
          pos[2] = '.';
          pos += 3;
          break;
        }
      }
      *pos++ = ']';
      *pos++ = '\n';
      call UDP.sendto(&session_endpoint, reply_buf, pos - reply_buf);
    }
  }

  command char *ShellCommand.getBuffer[uint8_t cmd_id](uint16_t len) {
    reply_buf[0] = '\0';
    if (len <= MAX_REPLY_LEN) return reply_buf;
    return NULL;
  }

  command void ShellCommand.write[uint8_t cmd_id](char *str, int len) {
    call UDP.sendto(&session_endpoint, str, len);    
  }

  void action_echo(int argc, char **argv) {
    int i, arg_len;
    char *payload = reply_buf;

    if (argc < 2) return;
    for (i = 1; i < argc; i++) {
      arg_len = strlen(argv[i]);
      if ((payload - reply_buf) + arg_len + 1 > MAX_REPLY_LEN) break;
      memcpy(payload, argv[i], arg_len);
      payload += arg_len;
      *payload = ' ';
      payload++;
    }
    *(payload - 1) = '\n';

    call UDP.sendto(&session_endpoint, reply_buf, payload - reply_buf);
  }

  void action_ping6(int argc, char **argv) {
    struct in6_addr dest;

    if (argc < 2) return;
        inet_pton6(argv[1], &dest);
    call ICMPPing.ping(&dest, 1024, 10);
  }


  void action_uptime(int argc, char **argv) {
#if defined(PLATFORM_TELOSB) || defined(PLATFORM_EPIC)
    int len;
    uint64_t tval = call Uptime.get();
    atomic
      tval = (uptime + tval - boot_time) / 1024;
    len = snprintf(reply_buf, MAX_REPLY_LEN, "up %li seconds\n",
                   (uint32_t)tval);
    call UDP.sendto(&session_endpoint, reply_buf, len);
#endif
  }

  void action_ident(int argc, char **argv) {
    call UDP.sendto(&session_endpoint, ident_string, strlen(ident_string));
  }

  // commands 
  struct cmd_name builtins[N_BUILTINS] = {{4, "help"},
                                          {4, "echo"},  
                                          {5, "ping6"},
                                          {6, "uptime"},
                                          {5, "ident"}};
  struct cmd_builtin builtin_actions[N_BUILTINS] = {{action_help},
                                                    {action_echo},
                                                    {action_ping6},
                                                    {action_uptime},
                                                    {action_ident}};


  // break up a command given as a string into a sequence of null terminated
  // strings, and initialize the argv array to point into it.
  void init_argv(char *cmd, uint16_t len, char **argv, int *argc) {
    int inArg = 0;
    *argc = 0;
    while (len > 0 && *argc < N_ARGS) {
      if (*cmd == ' ' || *cmd == '\n' || *cmd == '\t' || *cmd == '\0' || len == 1){
        if (inArg) {
          *argc = *argc + 1;
          inArg = 0;
          *cmd = '\0';
        }
      } else if (!inArg) {
        argv[*argc] = cmd;
        inArg = 1;
      }
      cmd ++;
      len --;
    }
  }

  int lookup_cmd(char *cmd, int dbsize, struct cmd_name *db) {
    int i;
    for (i = 0; i < dbsize; i++) {
      if (memcmp(cmd, db[i].c_name, db[i].c_len) == 0 
          && cmd[db[i].c_len] == '\0')
        return i;
    }
    return CMD_NO_CMD;
  }

  event void UDP.recvfrom(struct sockaddr_in6 *from, void *data, 
                          uint16_t len, struct ip_metadata *meta) {
    char *argv[N_ARGS];
    int argc, cmd;

    memcpy(&session_endpoint, from, sizeof(struct sockaddr_in6));
    init_argv((char *)data, len, argv, &argc);

    if (argc > 0) {
      cmd = lookup_cmd(argv[0], N_BUILTINS, builtins);
      if (cmd != CMD_NO_CMD) {
        builtin_actions[cmd].action(argc, argv);
        return;
      }
      cmd = lookup_cmd(argv[0], N_EXTERNAL, externals);
      if (cmd != CMD_NO_CMD) {
        char *reply = signal ShellCommand.eval[cmd](argc, argv);
        if (reply != NULL)
          call UDP.sendto(&session_endpoint, reply, strlen(reply));
        return;
      }
      cmd = snprintf(reply_buf, MAX_REPLY_LEN, "sdsh: %s: command not found\n", argv[0]);
      call UDP.sendto(&session_endpoint, reply_buf, cmd);
    }
  }

  event void ICMPPing.pingReply(struct in6_addr *source, struct icmp_stats *stats) {
    int len;
    len = inet_ntop6(source, reply_buf, MAX_REPLY_LEN);
    if (len > 0) {
      len += snprintf(reply_buf + len - 1, MAX_REPLY_LEN - len + 1, ping_fmt,
                      stats->seq, stats->ttl, stats->rtt);
      call UDP.sendto(&session_endpoint, reply_buf, len);
    }
  }

  event void ICMPPing.pingDone(uint16_t ping_rcv, uint16_t ping_n) {
    int len;
    len = snprintf(reply_buf, MAX_REPLY_LEN, ping_summary, ping_n, ping_rcv);
    call UDP.sendto(&session_endpoint, reply_buf, len);
  }

#if  defined(PLATFORM_TELOSB) || defined(PLATFORM_EPIC)
  async event void Uptime.overflow() {
    atomic
      uptime += 0xffffffff;
  }
#endif

  default event char *ShellCommand.eval[uint8_t cmd_id](int argc, char **argv) {
    return NULL;
  }
  default event char *RegisterShellCommand.getCommandName[uint8_t cmd_id]() {
    return NULL;
  }
}
