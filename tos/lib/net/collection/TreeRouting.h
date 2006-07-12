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
    uint8_t hopcount;
    uint16_t metric;
} route_info_t;

typedef struct {
    am_addr_t neighbor;
    route_info_t info;
} routing_table_entry;

inline void routeInfoInit(route_info_t *ri) {
    ri->parent = INVALID_ADDR;
    ri->hopcount = 0;
    ri->metric = 0;
}

typedef nx_struct beacon_msg_t {
    nx_am_addr_t parent;
    nx_uint8_t hopcount;
    nx_uint16_t metric;
} beacon_msg_t;

#endif
