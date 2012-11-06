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

#ifdef COAP_RESOURCE_ETSI_IOT_TEST
    INDEX_ETSI_TEST,
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
      (GET_SUPPORTED | PUT_SUPPORTED),
      0
    },
#endif

  //ETSI plugtest resources:
  //is used as dynamicresource
#ifdef COAP_RESOURCE_ETSI_IOT_TEST
  {
      INDEX_ETSI_TEST,
      "test", sizeof("test"),
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
      "", "",
#endif
      {0,0,0,0}, // uri_key will be set later
      (GET_SUPPORTED | PUT_SUPPORTED | POST_SUPPORTED | DELETE_SUPPORTED),
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
      (GET_SUPPORTED),
      0
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
#if (COAP_MAX_PDU_SIZE < 165)
#warning "*** XML requires COAP_MAX_PDU_SIZE > 165. Make sure you change the COAP_MAX_PDU_SIZE in /support/sdk/c/coap/config.h.tinyos to get XML working properly ***"
#endif
#define XML_PRE "<?xml version=\"1.0\" encoding=\"UTF-8\"?> <senml xmlns=\"urn:ietf:params:xml:ns:senml\""
#define XML_POST "</senml>"
#endif

#endif
