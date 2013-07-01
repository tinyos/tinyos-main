/*
 * Copyright (c) 2011 University of Bremen, TZI
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef _COAP_TINYOS_COAP_RESOURCES_H_
#define _COAP_TINYOS_COAP_RESOURCES_H_

#include <pdu.h>

#define SENSOR_VALUE_INVALID 0xFFFE
#define SENSOR_NOT_AVAILABLE 0xFFFF

//user defined resources

enum {
#ifdef COAP_RESOURCE_DEFAULT
    INDEX_DEFAULT,
#endif
#if defined (COAP_RESOURCE_TEMP) || defined (COAP_RESOURCE_ALL)
    INDEX_TEMP,
#endif
#if defined (COAP_RESOURCE_HUM) || defined (COAP_RESOURCE_ALL)
    INDEX_HUM,
#endif
#if defined (COAP_RESOURCE_VOLT) || defined (COAP_RESOURCE_ALL)
    INDEX_VOLT,
#endif
#ifdef COAP_RESOURCE_ALL
    INDEX_ALL,
#endif
#ifdef COAP_RESOURCE_KEY
    INDEX_KEY,
#endif
#ifdef COAP_RESOURCE_LED
    INDEX_LED,
#endif
#ifdef COAP_RESOURCE_ROUTE
    INDEX_ROUTE,
#endif

#ifdef COAP_RESOURCE_GIO_PINS
    INDEX_GIO,
#endif
#ifdef COAP_RESOURCE_DEV_0
    INDEX_DEV_0,
#endif
#ifdef COAP_RESOURCE_DEV_1
    INDEX_DEV_1,
#endif
#ifdef COAP_RESOURCE_DEV_2
    INDEX_DEV_2,
#endif
#ifdef COAP_RESOURCE_DEV_3
    INDEX_DEV_3,
#endif

#ifdef COAP_RESOURCE_ETSI_IOT_VALIDATE
    INDEX_ETSI_VALIDATE,
#endif
#ifdef COAP_RESOURCE_ETSI_IOT_SEPARATE
    INDEX_ETSI_SEPARATE,
#endif
#ifdef COAP_RESOURCE_ETSI_IOT_SEGMENT
    INDEX_ETSI_SEGMENT,
#endif
#ifdef COAP_RESOURCE_ETSI_IOT_LARGE
    INDEX_ETSI_LARGE,
#endif
#ifdef COAP_RESOURCE_ETSI_IOT_OBSERVE
    INDEX_ETSI_OBSERVE,
#endif
#ifdef COAP_RESOURCE_ETSI_IOT_MULTI_FORMAT
    INDEX_ETSI_MULTI_FORMAT,
#endif
#ifdef COAP_RESOURCE_ETSI_IOT_LINK
    INDEX_ETSI_LINK1,
    INDEX_ETSI_LINK2,
    INDEX_ETSI_LINK3,
    INDEX_ETSI_LINK4,
    INDEX_ETSI_LINK5,
    INDEX_ETSI_PATH,
    INDEX_ETSI_PATH1,
    INDEX_ETSI_PATH2,
    INDEX_ETSI_PATH3,
#endif
#ifdef COAP_RESOURCE_ETSI_IOT_LOCATION_QUERY
    INDEX_ETSI_LOCATION_QUERY,
#endif
#ifdef COAP_RESOURCE_ETSI_IOT_QUERY
    INDEX_ETSI_QUERY,
#endif

#ifdef COAP_RESOURCE_IPSO_DEV_MFG
    INDEX_IPSO_DEV_MFG,
#endif
#ifdef COAP_RESOURCE_IPSO_DEV_MDL
    INDEX_IPSO_DEV_MDL,
#endif
#ifdef COAP_RESOURCE_IPSO_DEV_SER
    INDEX_IPSO_DEV_SER,
#endif
#ifdef COAP_RESOURCE_IPSO_DEV_N
    INDEX_IPSO_DEV_N,
#endif
#ifdef COAP_RESOURCE_IPSO_DEV_BAT
    INDEX_IPSO_DEV_BAT,
#endif

    COAP_LAST_RESOURCE,
    COAP_NO_SUCH_RESOURCE = 0xff
};

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

#ifdef COAP_RESOURCE_KEY
typedef nx_struct config_t
{
  nx_uint8_t version;
  nx_uint8_t EUI64[8];
  nx_uint8_t KEY128[16];
} config_t;
#endif

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
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
  const unsigned char name[MAX_SENSOR_NAME_LENGTH];
  const unsigned char unit[2];
#endif
  coap_key_t uri_key;
  uint8_t max_age;
  uint8_t supported_methods:4;
  uint8_t observable:1;
} index_uri_key_t;

index_uri_key_t uri_index_map[COAP_LAST_RESOURCE] = {
#ifdef COAP_RESOURCE_DEFAULT
  {
      INDEX_DEFAULT,
      "", sizeof(""),
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
      "", "",
#endif
      {0,0,0,0}, // uri_key will be set later
      COAP_DEFAULT_MAX_AGE,
      (GET_SUPPORTED | PUT_SUPPORTED | POST_SUPPORTED | DELETE_SUPPORTED),
      0
  },
#endif
#if defined (COAP_RESOURCE_TEMP) || defined (COAP_RESOURCE_ALL)
  {
      INDEX_TEMP,
      "st", sizeof("st"),
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
      "temperature", "K",
#endif
      {0,0,0,0}, // uri_key will be set later
      COAP_DEFAULT_MAX_AGE,
      GET_SUPPORTED,
      0
  },
#endif
#if defined (COAP_RESOURCE_HUM) || defined (COAP_RESOURCE_ALL)
  {
      INDEX_HUM,
      "sh", sizeof("sh"),
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
      "humidity", "%",
#endif
      {0,0,0,0}, // uri_key will be set later
      COAP_DEFAULT_MAX_AGE,
      GET_SUPPORTED,
      0
  },
#endif
#if defined (COAP_RESOURCE_VOLT) || defined (COAP_RESOURCE_ALL)
  {
      INDEX_VOLT,
      "sv", sizeof("sv"),
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
      "voltage", "V",
#endif
      {0,0,0,0}, // uri_key will be set later
      COAP_DEFAULT_MAX_AGE,
      GET_SUPPORTED,
      0
  },
#endif
#ifdef COAP_RESOURCE_ALL
  {
      INDEX_ALL,
      "r", sizeof("r"),
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
      "", "",
#endif
      {0,0,0,0}, // uri_key will be set later
      COAP_DEFAULT_MAX_AGE,
      GET_SUPPORTED,
      0
  },
#endif
#ifdef COAP_RESOURCE_KEY
  {
      INDEX_KEY,
      "ck", sizeof("ck"),
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
      "", "",
#endif
      {0,0,0,0}, // uri_key will be set later
      COAP_DEFAULT_MAX_AGE,
      (GET_SUPPORTED | PUT_SUPPORTED),
      0
  },
#endif
#ifdef COAP_RESOURCE_LED
  {
      INDEX_LED,
      "l", sizeof("l"),
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
      "", "",
#endif
      {0,0,0,0}, // uri_key will be set later
      COAP_DEFAULT_MAX_AGE,
      (GET_SUPPORTED | PUT_SUPPORTED),
      1
  },
#endif
#ifdef COAP_RESOURCE_ROUTE
  {
      INDEX_ROUTE,
      "rt", sizeof("rt"),
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
      "", "",
#endif
      {0,0,0,0}, // uri_key will be set later
      COAP_DEFAULT_MAX_AGE,
      GET_SUPPORTED,
      0
  },
#endif

  //GPIO resources:
#ifdef COAP_RESOURCE_GIO_PINS
  {
    INDEX_GIO,
    "gio",  sizeof("gio"),
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
    "", "",
#endif
    {0,0,0,0}, // uri_key will be set later
    COAP_DEFAULT_MAX_AGE,
    (GET_SUPPORTED | PUT_SUPPORTED),
    0
  },
#endif
#ifdef COAP_RESOURCE_DEV_0
  {
    INDEX_DEV_0,
    "dev0", sizeof("dev0"),
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
    "", "",
#endif
    {0,0,0,0}, // uri_key will be set later
    COAP_DEFAULT_MAX_AGE,
    (GET_SUPPORTED | PUT_SUPPORTED),
      0
  },
#endif
#ifdef COAP_RESOURCE_DEV_1
    {
      INDEX_DEV_1,
      "dev1",  sizeof("dev1"),
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
      "", "",
#endif
      {0,0,0,0}, // uri_key will be set later
      COAP_DEFAULT_MAX_AGE,
      (GET_SUPPORTED | PUT_SUPPORTED),
      0
    },
#endif
#ifdef COAP_RESOURCE_DEV_2
    {
      INDEX_DEV_2,
      "dev2",  sizeof("dev2"),
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
      "", "",
#endif
      {0,0,0,0}, // uri_key will be set later
      COAP_DEFAULT_MAX_AGE,
      (GET_SUPPORTED | PUT_SUPPORTED),
      0
    },
#endif
#ifdef COAP_RESOURCE_DEV_3
    {
      INDEX_DEV_3,
      "dev3",  sizeof("dev3"),
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
      "", "",
#endif
      {0,0,0,0}, // uri_key will be set later
      COAP_DEFAULT_MAX_AGE,
      (GET_SUPPORTED | PUT_SUPPORTED),
      0
    },
#endif

  //ETSI plugtest resources:
#ifdef COAP_RESOURCE_ETSI_IOT_VALIDATE
  {
      INDEX_ETSI_VALIDATE,
      "validate", sizeof("validate"),
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
      "", "",
#endif
      {0,0,0,0}, // uri_key will be set later
      COAP_DEFAULT_MAX_AGE,
      (GET_SUPPORTED | PUT_SUPPORTED),
      0
  },
#endif
#ifdef COAP_RESOURCE_ETSI_IOT_SEPARATE
  {
      INDEX_ETSI_SEPARATE,
      "separate", sizeof("separate"),
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
      "", "",
#endif
      {0,0,0,0}, // uri_key will be set later
      COAP_DEFAULT_MAX_AGE,
      (GET_SUPPORTED | PUT_SUPPORTED),
      0
  },
#endif
#ifdef COAP_RESOURCE_ETSI_IOT_SEGMENT
  {
      INDEX_ETSI_SEGMENT,
      "seg1/seg2/seg3", sizeof("seg1/seg2/seg3"),
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
      "", "",
#endif
      {0,0,0,0}, // uri_key will be set later
      COAP_DEFAULT_MAX_AGE,
      (GET_SUPPORTED),
      0
  },
#endif
#ifdef COAP_RESOURCE_ETSI_IOT_LARGE
  {
      INDEX_ETSI_LARGE,
      "large", sizeof("large"),
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
      "", "",
#endif
      {0,0,0,0}, // uri_key will be set later
      COAP_DEFAULT_MAX_AGE,
      (GET_SUPPORTED),
      0
  },
#endif
#ifdef COAP_RESOURCE_ETSI_IOT_OBSERVE
  {
    INDEX_ETSI_OBSERVE,
    "obs", sizeof("obs"),
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
    "", "",
#endif
    {0,0,0,0}, // uri_key will be set later
    5,
    (GET_SUPPORTED | PUT_SUPPORTED),
    1
  },
#endif
#ifdef COAP_RESOURCE_ETSI_IOT_MULTI_FORMAT
  {
    INDEX_ETSI_MULTI_FORMAT,
    "multi-format", sizeof("multi-format"),
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
    "text", "t",
#endif
    {0,0,0,0}, // uri_key will be set later
    COAP_DEFAULT_MAX_AGE,
    (GET_SUPPORTED),
    0
  },
#endif
#ifdef COAP_RESOURCE_ETSI_IOT_LINK
  {
    INDEX_ETSI_LINK1,
    "link1", sizeof("link1"),
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
    "", "",
#endif
    {0,0,0,0}, // uri_key will be set later
    COAP_DEFAULT_MAX_AGE,
    (GET_SUPPORTED),
    0
  },
  {
    INDEX_ETSI_LINK2,
    "link2", sizeof("link2"),
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
    "", "",
#endif
    {0,0,0,0}, // uri_key will be set later
    COAP_DEFAULT_MAX_AGE,
    (GET_SUPPORTED),
    0
  },
  {
    INDEX_ETSI_LINK3,
    "link3", sizeof("link3"),
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
    "", "",
#endif
    {0,0,0,0}, // uri_key will be set later
    COAP_DEFAULT_MAX_AGE,
    (GET_SUPPORTED),
    0
  },
  {
    INDEX_ETSI_LINK4,
    "link4", sizeof("link4"),
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
    "", "",
#endif
    {0,0,0,0}, // uri_key will be set later
    COAP_DEFAULT_MAX_AGE,
    (GET_SUPPORTED),
    0
  },
  {
    INDEX_ETSI_LINK5,
    "lnk5", sizeof("lnk5"),  // NOTE: lnk5 not link5 !! for TD_COAP_LINK_08
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
    "", "",
#endif
    {0,0,0,0}, // uri_key will be set later
    COAP_DEFAULT_MAX_AGE,
    (GET_SUPPORTED),
    0
  },
  {
    INDEX_ETSI_PATH,
    "path", sizeof("path"),
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
    "", "",
#endif
    {0,0,0,0}, // uri_key will be set later
    COAP_DEFAULT_MAX_AGE,
    (GET_SUPPORTED),
    0
  },
  {
    INDEX_ETSI_PATH1,
    "path/sub1", sizeof("path/sub1"),
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
    "", "",
#endif
    {0,0,0,0}, // uri_key will be set later
    COAP_DEFAULT_MAX_AGE,
    (GET_SUPPORTED),
    0
  },
  {
    INDEX_ETSI_PATH2,
    "path/sub2", sizeof("path/sub3"),
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
    "", "",
#endif
    {0,0,0,0}, // uri_key will be set later
    COAP_DEFAULT_MAX_AGE,
    (GET_SUPPORTED),
    0
  },
  {
    INDEX_ETSI_PATH3,
    "path/sub3", sizeof("path/sub3"),
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
    "", "",
#endif
    {0,0,0,0}, // uri_key will be set later
    COAP_DEFAULT_MAX_AGE,
    (GET_SUPPORTED),
    0
  },
#endif
#ifdef COAP_RESOURCE_ETSI_IOT_LOCATION_QUERY
  {
    INDEX_ETSI_LOCATION_QUERY,
    "location-query", sizeof("location-query"),
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
    "", "",
#endif
    {0,0,0,0}, // uri_key will be set later
    COAP_DEFAULT_MAX_AGE,
    (GET_SUPPORTED | POST_SUPPORTED),
    0
  },
#endif
#ifdef COAP_RESOURCE_ETSI_IOT_QUERY
  {
    INDEX_ETSI_QUERY,
    "query", sizeof("query"),
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
    "", "",
#endif
    {0,0,0,0}, // uri_key will be set later
    COAP_DEFAULT_MAX_AGE,
    (GET_SUPPORTED),
    0
  },
#endif

#ifdef COAP_RESOURCE_IPSO_DEV_MFG
  {
      INDEX_IPSO_DEV_MFG,
      "dev/mfg", sizeof("dev/mfg"),
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
    "", "",
#endif
      {0,0,0,0}, // uri_key will be set later
      COAP_DEFAULT_MAX_AGE,
      (GET_SUPPORTED )
  },
#endif
#ifdef COAP_RESOURCE_IPSO_DEV_MDL
  {
      INDEX_IPSO_DEV_MDL,
      "dev/mdl", sizeof("dev/mdl"),
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
    "", "",
#endif
      {0,0,0,0}, // uri_key will be set later
      COAP_DEFAULT_MAX_AGE,
      (GET_SUPPORTED)
  },
#endif
#ifdef COAP_RESOURCE_IPSO_DEV_SER
  {
      INDEX_IPSO_DEV_SER,
      "dev/ser", sizeof("dev/ser"),
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
    "", "",
#endif
      {0,0,0,0}, // uri_key will be set later
      COAP_DEFAULT_MAX_AGE,
      (GET_SUPPORTED)
  },
#endif
#ifdef COAP_RESOURCE_IPSO_DEV_N
  {
      INDEX_IPSO_DEV_N,
      "dev/n", sizeof("dev/n"),
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
    "", "",
#endif
      {0,0,0,0}, // uri_key will be set later
      COAP_DEFAULT_MAX_AGE,
      (GET_SUPPORTED)
  },
#endif
#ifdef COAP_RESOURCE_IPSO_DEV_BAT
  {
      INDEX_IPSO_DEV_BAT,
      "dev/bat", sizeof("dev/bat"),
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
    "", "",
#endif
      {0,0,0,0}, // uri_key will be set later
      COAP_DEFAULT_MAX_AGE,
      (GET_SUPPORTED)
  },
#endif
};

//predefined strings for markup-languages

//JSON (SenML-formatted)
#ifdef COAP_CONTENT_TYPE_JSON
#define JSON_PRE " {\"e\":["
#endif

//XML (SenML-formatted)
#ifdef COAP_CONTENT_TYPE_XML
//#undef COAP_MAX_PDU_SIZE
//#define COAP_MAX_PDU_SIZE 165
//#warning "*** Content-Format XML: COAP_MAX_PDU_SIZE redefined to 165 ***"
#define XML_PRE "<?xml version=\"1.0\" encoding=\"UTF-8\"?> <senml xmlns=\"urn:ietf:params:xml:ns:senml\" "
#define XML_POST "</senml>"
#endif

#endif
