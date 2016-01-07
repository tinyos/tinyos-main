#ifndef _COAP_TINYOS_COAP_DEFS_H_
#define _COAP_TINYOS_COAP_DEFS_H_

#include <pdu.h>

#define SENSOR_VALUE_INVALID 0xFFFE
#define SENSOR_NOT_AVAILABLE 0xFFFF


typedef nx_struct val_all
{
  nx_uint8_t id_t:4;
  nx_uint8_t length_t:4;
  nx_uint16_t temp;
  nx_uint8_t id_h:4;
  nx_uint8_t length_h:4;
  nx_uint16_t hum;
  nx_uint8_t id_v:4;
  nx_uint8_t length_v:4;
  nx_uint16_t volt;
} val_all_t;


#define MAX_CONTENT_TYPE_LENGTH 2

#define GET_SUPPORTED 1
#define POST_SUPPORTED 2
#define PUT_SUPPORTED 4
#define DELETE_SUPPORTED 8

//uri properties for index<->uri_key conversion
typedef struct index_uri_key
{
  uint8_t index;
  const unsigned char uri[MAX_URI_LENGTH];
  uint8_t uri_len;
  coap_key_t uri_key;
  uint8_t max_age;
  uint8_t supported_methods:4;
  uint8_t observable:1;
} index_uri_key_t;

#endif
