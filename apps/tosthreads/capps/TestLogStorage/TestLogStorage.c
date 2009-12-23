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
 * TestLogStorage is a threaded implementation of an application that takes a dummy
 * sensor readings of a counter, logs it flash, and then sends it out over the
 * serial port at some later time. In the current implementation, each sensor reading is
 * taken once every 3000ms, and records containing a set of readings from each
 * iteration are batched out over the radio every 10000ms.  This application is
 * very similar to the SenseStoreAndForward application contained in this same
 * directory, except that it is written using a dummy sensor value instead of
 * sensors specific to the tmote onboard suite. In this way, the LogStorage
 * functionality can be tested in conjunction with the sending facility in a
 * platform independent way.
 * 
 * Readings are taken from the dummy sensor and logged to flash as one record in an
 * infinite loop. Records are then read out of flash and and sent out over the
 * serial interface in separate infinite loop.  Before the application starts
 * running, the entire contents of the flash drive are erased.
 * 
 * A successful test will result in LED0 remaining solid for approximately 6s while
 * the flash is being erased.  After that LED0 will toggle with each successful
 * sensor readings logged to flash, at a rate of 3000ms.  Also, LED1 will begin
 * toggling in rapid succession once every 10000ms as records are successfully read
 * from flash and sent out over the serial port.  Once all of the records currently
 * recorded to flash since the last batch of sends have been sent out, LED2 Toggles
 * to indicate completion.  This process continues in an infinite loop forever.
 *
 * @author Kevin Klues <klueska@cs.stanford.edu>
 */

#include "tosthread.h"
#include "tosthread_amserial.h"
#include "tosthread_leds.h"
#include "tosthread_threadsync.h"
#include "tosthread_logstorage.h"
#include "StorageVolumes.h"

#define NUM_SENSORS              1
#define SAMPLING_PERIOD       3000
#define SENDING_PERIOD       10000
#define AM_SENSOR_DATA_MSG    0x25   

//Data structure for storing sensor data
typedef struct sensor_data {
  nx_uint32_t seq_no;
  nx_uint16_t sample;
} sensor_data_t;

//Initialize variables associated with each thread
tosthread_t dummy_sensor;
tosthread_t store_handler;
tosthread_t send_handler;

message_t send_msg;
sensor_data_t storing_sensor_data;
sensor_data_t* sending_sensor_data; //pointer into message structure
mutex_t data_mutex;
mutex_t log_mutex;
barrier_t send_barrier;
barrier_t sense_barrier;

void sensor_thread(void* arg);
void store_thread(void* arg);
void send_thread(void* arg);

void tosthread_main(void* arg) {
  mutex_init(&data_mutex);
  mutex_init(&log_mutex);
  barrier_reset(&send_barrier, NUM_SENSORS+1);
  barrier_reset(&sense_barrier, NUM_SENSORS+1);
  sending_sensor_data = serialGetPayload(&send_msg, sizeof(sensor_data_t));
  storing_sensor_data.seq_no = 0;
  
  amSerialStart();
  led0Toggle();
  volumeLogErase(VOLUME_TESTLOGSTORAGE);
  volumeLogSeek(VOLUME_TESTLOGSTORAGE, SEEK_BEGINNING);
  tosthread_create(&dummy_sensor, sensor_thread, NULL, 200);
  tosthread_create(&store_handler, store_thread, NULL, 200);
  tosthread_create(&send_handler, send_thread, NULL, 200);
}

void read_sensor(error_t (*read)(uint16_t*), nx_uint16_t* nx_val) {

}

void sensor_thread(void* arg) {
  //Dummy sensor just counts up on each iteration
  uint16_t val = -1;
  for(;;) {
    val++;
    mutex_lock(&data_mutex);
    storing_sensor_data.sample = val;
    mutex_unlock(&data_mutex);
    barrier_block(&send_barrier);
    barrier_block(&sense_barrier);
  }
}

void store_thread(void* arg) {
  storage_len_t sensor_data_len;
  bool sensor_records_lost;

  for(;;) {
    barrier_block(&send_barrier);
    barrier_reset(&send_barrier, NUM_SENSORS + 1);
    
    mutex_lock(&log_mutex);
      sensor_data_len = sizeof(sensor_data_t);
      while( volumeLogAppend(VOLUME_TESTLOGSTORAGE, &storing_sensor_data, &sensor_data_len, &sensor_records_lost) != SUCCESS );
    mutex_unlock(&log_mutex);
    
    storing_sensor_data.seq_no++;
    led0Toggle();

    tosthread_sleep(SAMPLING_PERIOD);
    barrier_block(&sense_barrier);
    barrier_reset(&sense_barrier, NUM_SENSORS + 1);
  }
}
void send_thread(void* arg) {
  storage_len_t sensor_data_len;
  
  for(;;) {
    tosthread_sleep(SENDING_PERIOD);

    while( volumeLogCurrentReadOffset(VOLUME_TESTLOGSTORAGE) != volumeLogCurrentWriteOffset(VOLUME_TESTLOGSTORAGE) ) {
      sensor_data_len = sizeof(sensor_data_t);
      mutex_lock(&log_mutex);
        while( volumeLogRead(VOLUME_TESTLOGSTORAGE, sending_sensor_data, &sensor_data_len) != SUCCESS );
      mutex_unlock(&log_mutex);
      
      while( amSerialSend(AM_BROADCAST_ADDR, &send_msg, sizeof(sensor_data_t), AM_SENSOR_DATA_MSG) != SUCCESS );
      led1Toggle();
    }
    led2Toggle();
  }
}
