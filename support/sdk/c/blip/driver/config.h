#ifndef _CONFIG_H
#define _CONFIG_H

#include <net/if.h>

struct config {
  struct in6_addr router_addr;
  char proxy_dev[IFNAMSIZ];
  int channel;
};


int config_parse(const char *file, struct config *c);
int config_print(struct config *c);

#endif
