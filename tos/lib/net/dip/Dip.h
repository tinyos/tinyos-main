
#ifndef __DIP_H__
#define __DIP_H__

#define DIP_TAU_LOW (1024L)
#define DIP_TAU_HIGH (65535L)

#define UQ_DIP unique("DIP")
#define UQCOUNT_DIP uniqueCount("DIP")

#define DIP_UNKNOWN_VERSION 0xFFFFFFFF
#define DIP_UNKNOWN_INDEX 0xFFFF

typedef enum {
  ID_DIP_INVALID = 0x0,
  ID_DIP_SUMMARY = 0x1,
  ID_DIP_VECTOR = 0x2,
  ID_DIP_DATA = 0x3
} dip_msgid_t;

enum {
  AM_DIP = 0x84,
  AM_DIP_DATA_MSG = 0x84, // For MIG tool
  AM_DIP_MSG = 0x84, // For MIG tool
  AM_DIP_DATA = 0x84 // For MIG tool
};

typedef uint16_t dip_index_t;
typedef uint16_t dip_key_t;
typedef nx_uint16_t nx_dip_key_t;
typedef uint32_t dip_version_t;
typedef nx_uint32_t nx_dip_version_t;
typedef uint8_t dip_estimate_t;
typedef dip_index_t dip_hashlen_t;

typedef nx_struct dip_msg {
  nx_uint8_t type; // dip_msgid_t
  nx_uint8_t content[0];
} dip_msg_t;

typedef nx_struct dip_data_msg {
  nx_dip_key_t key;
  nx_dip_version_t version;
  nx_uint8_t size;
  nx_uint8_t data[0];
} dip_data_msg_t;

typedef nx_struct dip_vector_msg {
  nx_uint8_t unitLen;
  nx_uint32_t vector[0];
} dip_vector_msg_t;

typedef nx_struct dip_summary_msg {
  nx_uint8_t unitLen;
  nx_uint32_t salt;
  nx_uint32_t info[0];
} dip_summary_msg_t;

dip_estimate_t DIP_DATA_ESTIMATE;
dip_estimate_t DIP_MAX_ESTIMATE;
dip_estimate_t DIP_VECTOR_ESTIMATE;

#define DIP_SUMMARY_ENTRIES_PER_PACKET (DIP_SUMMARY_VALUES_PER_PACKET * 3)
#define DIP_VECTOR_ENTRIES_PER_PACKET (DIP_VECTOR_VALUES_PER_PACKET * 2)

#include "qsort.c"

/* TUNABLE PARAMETERS */

typedef nx_struct dip_data {
  nx_uint8_t data[16];
} dip_data_t;

#define DIP_SUMMARY_VALUES_PER_PACKET 2
#define DIP_VECTOR_VALUES_PER_PACKET 2

#endif
