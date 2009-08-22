/**
 * DHV header file.
 *
 * Define the interfaces and components.
 *
 * @author Thanh Dang
 * @author Seungweon Park
 *
 * @modified 1/3/2009   Added meaningful documentation.
 * @modified 8/28/2008  Defined DHV packet type and renamed the variable
 * @modified 8/28/2008  Take the source code from Dip
 **/


#ifndef __DHV_H__
#define __DHV_H__

#define DHV_TAU_LOW (1024L)
#define DHV_TAU_HIGH (65535L)

#define UQ_DHV unique("DHV")
#define UQCOUNT_DHV uniqueCount("DHV")

#define DHV_UNKNOWN_VERSION 0xFFFFFFFF
#define DHV_UNKNOWN_INDEX 0xFFFF
#define DHV_VERSION_LENGTH 4

#define VBIT_LENGTH 8

enum {
  AM_DHV_TEST_MSG = 0xAB
};


typedef enum {
  ID_DHV_INVALID = 0x0,
  ID_DHV_SUMMARY = 0x1,
  ID_DHV_VECTOR = 0x2,
  ID_DHV_DATA = 0x3,
  ID_DHV_HSUM = 0x4,
  ID_DHV_VBIT = 0x5,
  ID_DHV_VECTOR_REQ = 0x6
} dhv_msgid_t;

//status indicator : no action, ads, request
enum{
  ID_DHV_NO  = 0x0,
  ID_DHV_ADS = 0x1,
  ID_DHV_REQ = 0x2
};

enum {
  AM_DHV = 0x62,
  AM_DHV_DATA_MSG = 0x62, // For MIG tool
  AM_DHV_MSG = 0x62, // For MIG tool
  AM_DHV_DATA = 0x62 // For MIG tool
};

typedef uint16_t dhv_key_t;
typedef uint16_t dhv_index_t;
typedef nx_uint16_t nx_dhv_key_t;
typedef uint32_t dhv_version_t;
typedef nx_uint32_t nx_dhv_version_t;
typedef uint8_t dhv_estimate_t;
typedef dhv_index_t dhv_hashlen_t;

typedef nx_struct dhv_msg {
  nx_uint8_t type; 
  nx_uint8_t content[0];
} dhv_msg_t;

typedef nx_struct dhv_data_msg {
  nx_dhv_key_t key;
  nx_dhv_version_t version;
  nx_uint8_t size;
  nx_uint8_t data[0];
} dhv_data_msg_t;

typedef nx_struct dhv_vector_msg {
  nx_uint8_t unitLen;
  nx_uint32_t vector[0];
} dhv_vector_msg_t;

typedef nx_struct dhv_summary_msg {
  //nx_uint8_t unitLen;
  nx_uint32_t salt;
  nx_uint32_t info;
} dhv_summary_msg_t;

typedef nx_struct dhv_hsum_msg{
  nx_uint32_t salt;
  nx_uint32_t info;
  nx_uint32_t checksum;
} dhv_hsum_msg_t;

typedef nx_struct dhv_vbit_msg{
  nx_uint8_t numKey;
  nx_uint8_t bindex;
  nx_uint8_t vindex;
  nx_uint32_t salt;
  nx_uint32_t info; //include hash into vbit message
  nx_uint8_t vbit[0];
}dhv_vbit_msg_t;

typedef nx_struct dhv_data {
  nx_uint8_t data[16];
} dhv_data_t;


typedef nx_struct dhv_test_msg {
  nx_uint16_t id;
  nx_uint8_t count;
  nx_uint8_t isOk;
} dhv_test_msg_t;


/* TUNABLE PARAMETERS */
#define DHV_SUMMARY_VALUES_PER_PACKET 2
#define DHV_VECTOR_VALUES_PER_PACKET 2

#define DHV_SUMMARY_ENTRIES_PER_PACKET (DHV_SUMMARY_VALUES_PER_PACKET * 3)
#define DHV_VECTOR_ENTRIES_PER_PACKET (DHV_VECTOR_VALUES_PER_PACKET * 2)
#endif
