
#ifndef TEST_SERIAL_H
#define TEST_SERIAL_H

typedef nx_struct test_localtime_msg {
  nx_uint32_t time;
} test_localtime_msg_t;

enum {
  AM_TEST_LOCALTIME_MSG = 88,
};

#endif
