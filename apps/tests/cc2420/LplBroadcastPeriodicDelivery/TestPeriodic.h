
#ifndef TESTPERIODIC_H
#define TESTPERIODIC_H

typedef nx_struct TestPeriodicMsg {
  nx_uint8_t count;
} TestPeriodicMsg;

enum {
  AM_TESTPERIODICMSG = 0x5,
};

#endif

