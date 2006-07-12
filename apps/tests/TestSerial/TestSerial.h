
#ifndef TEST_SERIAL_H
#define TEST_SERIAL_H

typedef nx_struct TestSerialMsg {
  nx_uint16_t counter;
} TestSerialMsg;

enum {
  AM_TESTSERIALMSG = 9,
};

#endif
