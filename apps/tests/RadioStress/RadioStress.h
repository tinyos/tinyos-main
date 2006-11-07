#ifndef RADIO_COUNT_MSG_H
#define RADIO_COUNT_MSG_H

typedef nx_struct RadioCountMsg {
  nx_uint16_t counter;
} RadioCountMsg;

enum {
  AM_RADIOCOUNTMSG = 6,
};

#endif
