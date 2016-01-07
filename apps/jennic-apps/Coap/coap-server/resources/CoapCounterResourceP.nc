#include <pdu.h>
#include <async.h>
#include <resource.h>

generic module CoapCounterResourceP(uint8_t uri_key) {
  provides interface CoapResource;
  uses interface Timer<TMilli> as UpdateTimer;
  uses interface Leds;
} implementation {


  unsigned char buf[2];
  size_t size;
  uint8_t counter = 0;
  unsigned char *payload;
  char data[16];
  uint8_t data_len = 0;
  coap_pdu_t *temp_request;
  coap_pdu_t *response;
  bool lock = FALSE; //TODO: atomic
  coap_async_state_t *temp_async_state = NULL;
  coap_resource_t *temp_resource = NULL;
  unsigned int temp_content_format;

  unsigned char attr_name_ct[]  = "ct";
  unsigned char attr_value_ct[] = "0";

  command error_t CoapResource.initResourceAttributes(coap_resource_t *r) {
#ifdef COAP_CONTENT_TYPE_PLAIN
    coap_add_attr(r,
		  attr_name_ct, sizeof(attr_name_ct)-1,
		  attr_value_ct, sizeof(attr_value_ct)-1, 0);
#endif

    if ((r->data = (uint8_t *) coap_malloc(sizeof(data))) != NULL) {
      data_len = sprintf(data, "counter:%u", counter);
      memcpy(r->data, data, data_len);
      r->data_len = data_len;
    }
    // default ETAG (ASCII characters)
    r->etag = 0x61;

    return SUCCESS;
  }

  /////////////////////
  // GET:
  task void getMethod() {

    response = coap_new_pdu();
    response->hdr->code = COAP_RESPONSE_CODE(205);

#ifndef WITHOUT_OBSERVE
     if (temp_async_state->flags & COAP_ASYNC_OBSERVED){
       temp_resource->seq_num.length = sizeof(counter);
       temp_resource->seq_num.s = &counter;
       coap_add_option(response, COAP_OPTION_SUBSCRIPTION, temp_resource->seq_num.length, temp_resource->seq_num.s);
     }
#endif

     coap_add_option(response, COAP_OPTION_ETAG,
		    coap_encode_var_bytes(buf, temp_resource->etag), buf);

     coap_add_option(response, COAP_OPTION_CONTENT_TYPE,
		     coap_encode_var_bytes(buf, temp_content_format), buf);

     if (temp_resource->max_age != COAP_DEFAULT_MAX_AGE)
       coap_add_option(response, COAP_OPTION_MAXAGE,
      	      coap_encode_var_bytes(buf, temp_resource->max_age), buf);

    signal CoapResource.methodDone(SUCCESS,
				   temp_async_state,
				   temp_request,
				   response,
				   temp_resource);
    lock = FALSE;
  }

  event void UpdateTimer.fired() {
    //call Leds.led1Toggle();
    counter++;

    temp_resource->dirty = 1;
    temp_resource->etag++; //ASCII chars
    //temp_resource->etag = (temp_resource->etag + 1) << 2; //non-ASCII chars

    temp_resource->seq_num.length = sizeof(counter);
    temp_resource->seq_num.s = &counter;

    if (temp_resource->data != NULL) {
	coap_free(temp_resource->data);
    }
    if ((temp_resource->data = (uint8_t *) coap_malloc(sizeof(data))) != NULL) {
      data_len = sprintf(data, "counter:%u", counter);
      memcpy(temp_resource->data, data, data_len);
      temp_resource->data_len = data_len;
      temp_resource->data_ct = temp_content_format;
    }

    signal CoapResource.notifyObservers();
  }

  command int CoapResource.getMethod(coap_async_state_t* async_state,
				     coap_pdu_t* request,
				     struct coap_resource_t *resource,
				     unsigned int content_format) {
    if (lock == FALSE) {
      lock = TRUE;
      temp_async_state = async_state;
      temp_request = request;
      temp_resource = resource;
      temp_content_format = COAP_MEDIATYPE_TEXT_PLAIN;

      if (!call UpdateTimer.isRunning() && async_state->flags & COAP_ASYNC_OBSERVED) {
	call UpdateTimer.startPeriodic(5000);
	counter = 0;
    //call Leds.led0On();
      } else {
	call UpdateTimer.stop();
    //call Leds.led0Off();
      }

      post getMethod();
    //call Leds.led2Toggle();
      return COAP_SPLITPHASE;
    } else {
      return COAP_RESPONSE_503;
    }
  }



  command int CoapResource.putMethod(coap_async_state_t* async_state,
				     coap_pdu_t* request,
				     coap_resource_t *resource,
				     unsigned int content_format) {
     return COAP_RESPONSE_405;
  }

  command int CoapResource.postMethod(coap_async_state_t* async_state,
				      coap_pdu_t* request,
				      struct coap_resource_t *resource,
				      unsigned int content_format) {
    return COAP_RESPONSE_405;
  }

  command int CoapResource.deleteMethod(coap_async_state_t* async_state,
					coap_pdu_t* request,
					struct coap_resource_t *resource) {
    return COAP_RESPONSE_405;
  }
}
