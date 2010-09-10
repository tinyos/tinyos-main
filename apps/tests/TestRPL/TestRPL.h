#ifndef TEST_RPL_H
#define TEST_RPL_H

typedef nx_struct radio_count_msg {
  nx_uint16_t counter;
} radio_count_msg_t;

enum {
  AM_RADIO_COUNT_MSG = 6,
};

#endif
