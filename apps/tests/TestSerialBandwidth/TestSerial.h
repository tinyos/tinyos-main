#ifndef TEST_SERIAL_H
#define TEST_SERIAL_H
typedef nx_struct TestSerialMsg {
  nx_uint16_t counter;
  nx_uint8_t x[TOSH_DATA_LENGTH-sizeof(nx_uint16_t)];
} TestSerialMsg;

enum {
  AM_TESTSERIALMSG = 9,
};
#endif
