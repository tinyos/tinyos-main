/*
 * Copyright (c) 2008 Stanford University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * BaseStation is a reimplementation of the standard BaseStation application using
 * the TOSThreads thread library.  It transparently forwards any AM messages it
 * receives from its radio interface to its serial interface and vice versa.
 *
 * <p>On the serial link, BaseStation sends and receives simple active
 * messages (not particular radio packets): on the radio link, it
 * sends radio active messages, whose format depends on the network
 * stack being used. BaseStation will copy its compiled-in group ID to
 * messages moving from the serial link to the radio, and will filter
 * out incoming radio messages that do not contain that group ID.</p>
 *
 * <p>BaseStation includes queues in both directions, with a guarantee
 * that once a message enters a queue, it will eventually leave on the
 * other interface. The queues allow the BaseStation to handle load
 * spikes.</p>
 *
 * <p>BaseStation acknowledges a message arriving over the serial link
 * only if that message was successfully enqueued for delivery to the
 * radio link.</p>
 *
 * <p>The LEDS are programmed to toggle as follows:</p>
 * <ul>
 * <li><b>LED0:</b> Message bridged from serial to radio</li>
 * <li><b>LED1:</b> Message bridged from radio to serial</li>
 * <li><b>LED2:</b> Dropped message due to queue overflow in either direction</li>
 * </ul>
 *
 * @author Kevin Klues <klueska@cs.stanford.edu>
 */

//#include "stack.h"
#include "tosthread.h"
#include "tosthread_amradio.h"
#include "tosthread_amserial.h"
#include "tosthread_leds.h"
#include "tosthread_threadsync.h"

#define MSG_QUEUE_SIZE  3

//Parameters associated with each of the two base station paths
// radio -> serial
// serial -> radio
typedef struct bs_params {
  tosthread_t receive_handle;
  tosthread_t snoop_handle;
  tosthread_t send_handle;
  mutex_t     mutex;
  condvar_t   condvar;
  message_t   shared_msgs[MSG_QUEUE_SIZE];
  uint8_t     shared_msg_queue_size;
  uint8_t     shared_msg_queue_index;
} bs_params_t;

//Declare parameters associated with radio RX thread
bs_params_t radioRx_params;
void radioReceive_thread(void* arg);
void radioSnoop_thread(void* arg);
void serialSend_thread(void* arg);

//Declare parameters associated with serial RX thread
bs_params_t serialRx_params;
void serialReceive_thread(void* arg);
void radioSend_thread(void* arg);

/********* Initialize base station parameters ********/
void bs_params_init(bs_params_t* p) {
  mutex_init( &(p->mutex) );
  condvar_init( &(p->condvar) );
  p->shared_msg_queue_size = 0;
  p->shared_msg_queue_index = 0;
}

/*********** Main function thread ************/
void tosthread_main(void* arg) {
  bs_params_init( &radioRx_params );
  bs_params_init( &serialRx_params );

  amRadioStart();
  amSerialStart();
  tosthread_create(&(radioRx_params.receive_handle), radioReceive_thread, NULL, 200);
  tosthread_create(&(radioRx_params.snoop_handle), radioSnoop_thread, NULL, 200);
  tosthread_create(&(radioRx_params.send_handle), serialSend_thread, NULL, 200);
  tosthread_create(&(serialRx_params.receive_handle), serialReceive_thread, NULL, 200);
  tosthread_create(&(serialRx_params.send_handle), radioSend_thread, NULL, 200);
}

/******************** Enqueue and dequeue Messages ****************/
error_t enqueueMsg(bs_params_t* p, message_t* m) {
  if(p->shared_msg_queue_size < MSG_QUEUE_SIZE) {
    (p->shared_msgs)[p->shared_msg_queue_index] = *m;
    (p->shared_msg_queue_index) = (p->shared_msg_queue_index + 1) % MSG_QUEUE_SIZE;
    (p->shared_msg_queue_size)++;
    return SUCCESS;
  }
  return FAIL;
}

message_t* dequeueMsg(bs_params_t* p) {
  if(p->shared_msg_queue_size > 0) {
    message_t* m;
    m = &((p->shared_msgs)[(p->shared_msg_queue_index + (MSG_QUEUE_SIZE - p->shared_msg_queue_size)) % MSG_QUEUE_SIZE]);
    (p->shared_msg_queue_size)--;
    return m;
  }
  return NULL;
}

/******************** Send Serial vs. Radio Messages ****************/
error_t sendSerialMsg(message_t* msg) {
  am_id_t   id     = amRadioGetType(msg);
  am_addr_t source = amRadioGetSource(msg);
  am_addr_t dest   = amRadioGetDestination(msg);
  uint8_t   len    = radioGetPayloadLength(msg);
  serialClear(msg);
  amSerialSetSource(msg, source);
      
  return amSerialSend(dest, msg, len, id);
}

error_t sendRadioMsg(message_t* msg) {
  am_id_t   id     = amSerialGetType(msg);
  am_addr_t source = amSerialGetSource(msg);
  am_addr_t dest   = amSerialGetDestination(msg);
  uint8_t   len    = serialGetPayloadLength(msg);
  radioClear(msg);
  amRadioSetSource(msg, source);
      
  return amRadioSend(dest, msg, len, id);
}


/***********************************************************/
/** Generic implementations of send/receive functionality **/ 
/***********************************************************/
void bs_receive(error_t (*recv_func)(message_t*, uint32_t, am_id_t), bs_params_t* p) {
  message_t m;
  
  for(;;) {
    if( (*(recv_func))(&m, 0, AM_RECEIVE_FROM_ANY) == SUCCESS ) {
      led0Toggle();

      mutex_lock( &(p->mutex) );
        while( enqueueMsg(p, &m) == FAIL )
          condvar_wait( &(p->condvar), &(p->mutex) );
      mutex_unlock( &(p->mutex) );
      condvar_signalAll( &(p->condvar) );
    }
    else led2Toggle();
  }
}

void bs_send(void* send_func, bs_params_t* p) {
  message_t m;
  message_t* m_ptr;
  
  for(;;) {
    mutex_lock( &(p->mutex) );
      while( (m_ptr = dequeueMsg(p)) == NULL )
        condvar_wait( &(p->condvar), &(p->mutex) );
      m = *m_ptr;
    mutex_unlock( &(p->mutex) );    
    condvar_signalAll( &(p->condvar) );
    
    if(send_func == amSerialSend)
      sendSerialMsg(&m);
    else
      sendRadioMsg(&m);
    led1Toggle();
  }  
}

/******************** Actual thread implementations ******************/
void radioReceive_thread(void* arg) {
  bs_receive(amRadioReceive, &radioRx_params);
}
void radioSnoop_thread(void* arg) {
  bs_receive(amRadioSnoop, &radioRx_params);
}
void serialSend_thread(void* arg) {
  bs_send(amSerialSend, &radioRx_params);
}
void serialReceive_thread(void* arg) {
  bs_receive(amSerialReceive, &serialRx_params);
}
void radioSend_thread(void* arg) {
  bs_send(amRadioSend, &serialRx_params);
}
