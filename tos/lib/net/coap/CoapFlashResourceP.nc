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

#include "tinyos_coap_resources.h"

generic module CoapFlashResourceP(uint8_t uri_key) {
  provides interface ReadResource;
  provides interface WriteResource;
  uses interface ConfigStorage;
} implementation {

  bool lock = FALSE;
  coap_tid_t temp_id;
  config_t conf;

  enum {
    CONFIG_ADDR = 0
  };

  /////////////
  //GET
  /////////////

  event void ConfigStorage.readDone(storage_addr_t addr, void* buf,
				    storage_len_t len, error_t err)  {
    if (err == SUCCESS) {
      memcpy(&conf, buf, len);
    } else {
      //printf("Read flash not successful\n");
    }

    signal ReadResource.getDone(err, temp_id, 0, buf, sizeof(conf));
    lock = FALSE;
  }

  command int ReadResource.get(coap_tid_t id) {
    if (lock == FALSE) {
      lock = TRUE;
      temp_id = id;

      if (call ConfigStorage.valid() == TRUE) {
	if (call ConfigStorage.read(CONFIG_ADDR, &conf, sizeof(conf)) != SUCCESS) {
	  //printf("Config.read not successful \n");
	  lock = FALSE;
	  return COAP_RESPONSE_500;
	} else {
	  return COAP_SPLITPHASE;
	}
      } else {
	lock = FALSE;
	return COAP_RESPONSE_500;
      }
    } else {
      lock = FALSE;
      return COAP_RESPONSE_503;
    }
  }

  /////////////
  //PUT
  /////////////

#warning "FIXME: CoAP: PreAck not implemented for put"

  event void ConfigStorage.commitDone(error_t err) {
    lock = FALSE;
    signal WriteResource.putDone(err, temp_id, 0);
  }

  event void ConfigStorage.writeDone(storage_addr_t addr, void *buf,
				     storage_len_t len, error_t err) {
    if (err == SUCCESS) {
      if (call ConfigStorage.commit() != SUCCESS) {
	signal WriteResource.putDone(err, temp_id, 0);
	lock = FALSE;
      }
    } else {
      signal WriteResource.putDone(err, temp_id, 0);
      lock = FALSE;
    }
  }

  command int WriteResource.put(uint8_t *val, size_t buflen, coap_tid_t id) {
    if (lock == FALSE) {
      if (uri_key == KEY_KEY && buflen < sizeof(conf)) {
	return COAP_RESPONSE_500;
      }

      lock = TRUE;
      temp_id = id;

      memcpy(&conf, val, buflen);

      if (call ConfigStorage.write(CONFIG_ADDR, &conf, sizeof(conf)) != SUCCESS) {
	//printf("Config.write not successful\n");
	lock = FALSE;
	return COAP_RESPONSE_500;
      } else {
	return COAP_SPLITPHASE;
      }
    } else {
      lock = FALSE;
      return COAP_RESPONSE_503;
    }
  }
}
