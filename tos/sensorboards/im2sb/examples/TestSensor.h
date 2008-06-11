#ifndef TEST_SENSOR_H
#define TEST_SENSOR_H

typedef nx_struct TestSensorMsg {
  nx_uint16_t value;
} TestSensorMsg;

enum {
  AM_TESTSENSORMSG = 10,
};

#endif
