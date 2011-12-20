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

//uri properties for uri<->key conversion
typedef struct key_uri
{
    uint8_t key;
    char uri[MAX_URI_LENGTH];
    uint8_t urilen;
    uint8_t mediatype;
    uint8_t writable:1;
    uint8_t splitphase:1;
    uint8_t immediately:1;
} key_uri_t;


//user defined resources

enum {
#if defined (COAP_RESOURCE_TEMP) || defined (COAP_RESOURCE_ALL)
    KEY_TEMP,
#endif
#if defined (COAP_RESOURCE_HUM) || defined (COAP_RESOURCE_ALL)
    KEY_HUM,
#endif
#if defined (COAP_RESOURCE_VOLT) || defined (COAP_RESOURCE_ALL)
    KEY_VOLT,
#endif
#ifdef COAP_RESOURCE_KEY
    KEY_KEY,
#endif
#ifdef COAP_RESOURCE_LED
    KEY_LED,
#endif
#ifdef COAP_RESOURCE_ALL
    KEY_ALL,
#endif
#ifdef COAP_RESOURCE_ROUTE
    KEY_ROUTE,
#endif
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

typedef nx_struct config_t
{
  nx_uint8_t version;
  nx_uint8_t EUI64[8];
  nx_uint8_t KEY128[16];
} config_t;

key_uri_t uri_key_map[NUM_URIS] = {
#ifdef COAP_RESOURCE_TEMP
    { KEY_TEMP, "st", sizeof("st"),
      COAP_MEDIATYPE_APPLICATION_OCTET_STREAM, 0, 1, 0},
#endif
#ifdef COAP_RESOURCE_HUM
    { KEY_HUM,  "sh",  sizeof("sh") ,
      COAP_MEDIATYPE_APPLICATION_OCTET_STREAM, 0, 1, 0},
#endif
#ifdef COAP_RESOURCE_VOLT
    { KEY_VOLT,  "sv",  sizeof("sv") ,
      COAP_MEDIATYPE_APPLICATION_OCTET_STREAM, 0, 1, 0},
#endif
#ifdef COAP_RESOURCE_KEY
    { KEY_KEY,  "ck",  sizeof("ck") ,
      COAP_MEDIATYPE_APPLICATION_OCTET_STREAM, 1, 1, 0},
#endif
#ifdef COAP_RESOURCE_LED
    { KEY_LED,  "l",  sizeof("l") ,
      COAP_MEDIATYPE_APPLICATION_OCTET_STREAM, 1, 1, 1},
#endif
#ifdef COAP_RESOURCE_ALL
    { KEY_ALL,  "r",  sizeof("r") ,
      COAP_MEDIATYPE_APPLICATION_OCTET_STREAM, 0, 1, 0},
#endif
#ifdef COAP_RESOURCE_ROUTE
    { KEY_ROUTE,  "rt",  sizeof("rt") ,
      COAP_MEDIATYPE_APPLICATION_OCTET_STREAM, 0, 1, 0},
#endif
};

#endif
