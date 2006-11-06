#ifndef _TREE_ROUTING_H
#define _TREE_ROUTING_H

enum {
    AM_TREE_ROUTING_CONTROL = 0xCE,
    BEACON_INTERVAL = 8192, 
    INVALID_ADDR  = TOS_BCAST_ADDR,
    ETX_THRESHOLD = 50,      // link quality=20% -> ETX=5 -> Metric=50 
    PARENT_SWITCH_THRESHOLD = 15,
    MAX_METRIC = 0xFFFF,
}; 
 

typedef struct {
  am_addr_t parent;
  uint16_t etx;
  bool haveHeard;
  bool congested;
} route_info_t;

typedef struct {
  am_addr_t neighbor;
  route_info_t info;
} routing_table_entry;

inline void routeInfoInit(route_info_t *ri) {
    ri->parent = INVALID_ADDR;
    ri->etx = 0;
    ri->haveHeard = 0;
    ri->congested = FALSE;
}

#endif
