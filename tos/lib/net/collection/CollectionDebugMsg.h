#ifndef _COLLECTION_UART_MSG
#define _COLLECTION_UART_MSG

#include "AM.h"

//Comment format ->   :meaning:args
enum {
    NET_C_DEBUG_STARTED = 0xDE,

    NET_C_FE_MSG_POOL_EMPTY = 0x10,    //::no args
    NET_C_FE_SEND_QUEUE_FULL = 0x11,   //::no args
    NET_C_FE_NO_ROUTE = 0x12,          //::no args
    NET_C_FE_SUBSEND_OFF = 0x13,
    NET_C_FE_SUBSEND_BUSY = 0x14,
    NET_C_FE_BAD_SENDDONE = 0x15,
    NET_C_FE_QENTRY_POOL_EMPTY = 0x16,
    NET_C_FE_SUBSEND_SIZE = 0x17,
    NET_C_FE_LOOP_DETECTED = 0x18,
    NET_C_FE_SEND_BUSY = 0x19,

    NET_C_FE_SENDQUEUE_EMPTY = 0x50,
    NET_C_FE_PUT_MSGPOOL_ERR = 0x51,
    NET_C_FE_PUT_QEPOOL_ERR = 0x52,
    NET_C_FE_GET_MSGPOOL_ERR = 0x53,
    NET_C_FE_GET_QEPOOL_ERR = 0x54,

    NET_C_FE_SENT_MSG = 0x20,  //:app. send       :msg uid, origin, next_hop
    NET_C_FE_RCV_MSG =  0x21,  //:next hop receive:msg uid, origin, last_hop
    NET_C_FE_FWD_MSG =  0x22,  //:fwd msg         :msg uid, origin, next_hop
    NET_C_FE_DST_MSG =  0x23,  //:base app. recv  :msg_uid, origin, last_hop
    NET_C_FE_SENDDONE_FAIL = 0x24,
    NET_C_FE_SENDDONE_WAITACK = 0x25,
    NET_C_FE_SENDDONE_FAIL_ACK_SEND = 0x26,
    NET_C_FE_SENDDONE_FAIL_ACK_FWD  = 0x27,
    NET_C_FE_DUPLICATE_CACHE = 0x28,  //dropped duplicate packet seen in cache
    NET_C_FE_DUPLICATE_QUEUE = 0x29,  //dropped duplicate packet seen in queue
    NET_C_FE_DUPLICATE_CACHE_AT_SEND = 0x2A,  //dropped duplicate packet seen in cache


    NET_C_TREE_NO_ROUTE   = 0x30,   //:        :no args
    NET_C_TREE_NEW_PARENT = 0x31,   //:        :parent_id, hopcount, metric
    NET_C_TREE_ROUTE_INFO = 0x32,   //:periodic:parent_id, hopcount, metric
    NET_C_TREE_SENT_BEACON = 0x33,
    NET_C_TREE_RCV_BEACON = 0x34,

    NET_C_DBG_1 = 0x40,             //:any     :uint16_t a
    NET_C_DBG_2 = 0x41,             //:any     :uint16_t a, b, c
    NET_C_DBG_3 = 0x42,             //:any     :uint16_t a, b, c
};

typedef nx_struct CollectionDebugMsg {
    nx_uint8_t type;
    nx_union {
        nx_uint16_t arg;
        nx_struct {
            nx_uint16_t msg_uid;   
            nx_am_addr_t origin;
            nx_am_addr_t other_node;
        } msg;
        nx_struct {
            nx_am_addr_t parent;
            nx_uint8_t hopcount;
            nx_uint16_t metric;
        } route_info;
        nx_struct {
            nx_uint16_t a;
            nx_uint16_t b;
            nx_uint16_t c;
        } dbg;
    } data;
    nx_uint16_t seqno;
} CollectionDebugMsg;

#endif
