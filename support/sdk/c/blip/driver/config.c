
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>

#include "ip.h"
#include "config.h"
#include "logging.h"

#define BUF_LEN 200

void rm_comment (char *buf) {
  while (*buf != '#' && *buf != '\0')
    buf++;
  *buf = '\0';
}

void upd_start(char **buf) {
  while ((**buf == ' ' || **buf == '\t' || **buf == '\n') && **buf != '\0')
    *buf = (*buf) + 1;
}

int config_parse(const char *file, struct config *c) {
  char *buf, real_buf[BUF_LEN], arg[BUF_LEN];
  FILE *fp = fopen(file, "r");
  int gotargs = 0;
  if (fp == NULL) return 1;

  while (fgets(real_buf, BUF_LEN, fp) != NULL) {
    buf = real_buf;
    rm_comment(buf);
    upd_start(&buf);
    if (sscanf(buf, "addr %s\n", arg) > 0) {
      inet_pton6(arg, &c->router_addr);
      gotargs ++;
    } else if (sscanf(buf, "proxy %s\n", c->proxy_dev) > 0) {
      gotargs ++;
    } else if (sscanf(buf, "channel %i\n", &c->channel) > 0) {
      if (c->channel < 11 || c->channel > 26) {
        fatal("Invalid channel specified in '%s'\n", file);
        exit(1);
      }
      gotargs ++;
    } else if (sscanf(buf, "log %s\n", arg) > 0) {
      int i;
      for (i = 0; i < 5; i++) {
        if (strncmp(log_names[i], arg, strlen(log_names[i])) == 0) {
          info("Read log level: %s\n", arg);
          log_setlevel(i);
          break;
        }
      }
    } else if (*buf != '\0') {
      // anything else indicates that there's invalid input.
      return 1;
    }
  }
  fclose(fp);

  if (gotargs != 3) return 1;

  info("Read config from '%s'\n", file);
  info("\tProxying neighbor advertisements to %s\n", c->proxy_dev);
  info("\tUsing channel %i\n", c->channel);
  return 0;
}

int config_print(struct config *c) {
  char buf[64];
  printf ("configuration:\n");
  inet_ntop(AF_INET6, &c->router_addr, buf, 64);
  printf ("  router address: %s\n", buf);
  printf("  proxy dev: %s\n", c->proxy_dev);
  printf("  channel: %i\n", c->channel);
  return 0;
}
