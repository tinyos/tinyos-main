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
  coap_tid_t id_t;
  config_t conf;

  enum {
    CONFIG_ADDR = 0
  };

  event void ConfigStorage.readDone(storage_addr_t addr, void* buf,
				    storage_len_t len, error_t err)  {

    //TODO: handle case where storage has NOT been written before -> 255
    if (err == SUCCESS) {
      memcpy(&conf, buf, len);
    }
    else {
      printf("Read flash not successful \n"); // Handle failure.
    }

    signal ReadResource.getDone(err, id_t, 0, buf, sizeof(conf));
  }

  event void ConfigStorage.writeDone(storage_addr_t addr, void *buf,
				     storage_len_t len, error_t err) {
    if (err == SUCCESS) {
      if (call ConfigStorage.commit() != SUCCESS) {
	//         handle this case
      }
    }
    else {
      // Handle failure
    }
    signal WriteResource.putDone(err, id_t, 0);
  }

  event void ConfigStorage.commitDone(error_t err) {
  }


  command error_t ReadResource.get(coap_tid_t id) {
    id_t = id;

    if (call ConfigStorage.valid() == TRUE) {
      if (call ConfigStorage.read(CONFIG_ADDR, &conf, sizeof(conf)) != SUCCESS) {
	printf("Config.read not successful \n");
	return FAIL;
      }
    } else {
      // Invalid volume.  Commit to make valid.
      printf( "invalid volume \n");
      if (call ConfigStorage.commit() == SUCCESS) {
      }
      else {
	// Handle failure
      }
    }

    return SUCCESS;
  }

  command error_t WriteResource.put(uint8_t *val, uint8_t buflen, coap_tid_t id) {
    id_t = id;

    if (uri_key == KEY_KEY && buflen < sizeof(conf))
      return FAIL; //handle this case
    memcpy(&conf, val, buflen);

    if (call ConfigStorage.valid() == TRUE) {
      if (call ConfigStorage.write(CONFIG_ADDR, &conf, sizeof(conf)) != SUCCESS) {
	printf("Config.write not s \n");
	return FAIL;
      }
    }
    else {
      // Invalid volume.  Commit to make valid.
      printf("invalid volume \n");
      if (call ConfigStorage.commit() == SUCCESS) {
      }
      else {
	// Handle failure
      }
    }

    return SUCCESS;
  }
  }
