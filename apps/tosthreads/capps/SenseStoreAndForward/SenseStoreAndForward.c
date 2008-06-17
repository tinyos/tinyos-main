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
 * @author Kevin Klues <klueska@cs.stanford.edu>
 */

#include "tosthread.h"
#include "tosthread_amradio.h"
#include "tosthread_leds.h"
#include "tosthread_threadsync.h"
#include "tosthread_logstorage.h"
#include "tmote_onboard_sensors.h"
#include "StorageVolumes.h"

#define NUM_SENSORS              4
#define SAMPLING_PERIOD       3000
#define SENDING_PERIOD       10000
#define AM_SENSOR_DATA_MSG    0x25   

//Data structure for storing sensor data
typedef struct sensor_data {
  nx_uint32_t seq_no;
  nx_uint16_t hum;
  nx_uint16_t temp;
  nx_uint16_t tsr;
  nx_uint16_t par;
} sensor_data_t;

//Initialize variables associated with each thread
tosthread_t humidity;
tosthread_t temperature;
tosthread_t total_solar;
tosthread_t photo_active;
tosthread_t store_handler;
tosthread_t send_handler;

message_t send_msg;
sensor_data_t storing_sensor_data;
sensor_data_t* sending_sensor_data; //pointer into message structure
mutex_t data_mutex;
mutex_t log_mutex;
barrier_t send_barrier;
barrier_t sense_barrier;

void humidity_thread(void* arg);
void temperature_thread(void* arg);
void total_solar_thread(void* arg);
void photo_active_thread(void* arg);
void store_thread(void* arg);
void send_thread(void* arg);

void tosthread_main(void* arg) {
  mutex_init(&data_mutex);
  mutex_init(&log_mutex);
  barrier_reset(&send_barrier, NUM_SENSORS+1);
  barrier_reset(&sense_barrier, NUM_SENSORS+1);
  sending_sensor_data = radioGetPayload(&send_msg, sizeof(sensor_data_t));
  storing_sensor_data.seq_no = 0;

  amRadioStart();
  led0Toggle();
  volumeLogErase(VOLUME_SENSORLOG);
  volumeLogSeek(VOLUME_SENSORLOG, SEEK_BEGINNING);
  tosthread_create(&humidity, humidity_thread, NULL, 200);
  tosthread_create(&temperature, temperature_thread, NULL, 200);
  tosthread_create(&total_solar, total_solar_thread, NULL, 200);
  tosthread_create(&photo_active, photo_active_thread, NULL, 200);
  tosthread_create(&store_handler, store_thread, NULL, 200);
  tosthread_create(&send_handler, send_thread, NULL, 200);
}

void read_sensor(error_t (*read)(uint16_t*), nx_uint16_t* nx_val) {
  uint16_t val;
  for(;;) {
    (*read)(&val);
    mutex_lock(&data_mutex);
    *nx_val = val;
    mutex_unlock(&data_mutex);
    barrier_block(&send_barrier);
    barrier_block(&sense_barrier);
  }
}

void humidity_thread(void* arg) {
  read_sensor(sensirionSht11_humidity_read, &(storing_sensor_data.hum));
}
void temperature_thread(void* arg) {
  read_sensor(sensirionSht11_temperature_read, &(storing_sensor_data.temp));
}
void total_solar_thread(void* arg) {
  read_sensor(hamamatsuS10871_tsr_read, &(storing_sensor_data.tsr));
}
void photo_active_thread(void* arg) {
  read_sensor(hamamatsuS1087_par_read, &(storing_sensor_data.par));
}
void store_thread(void* arg) {
  storage_len_t sensor_data_len;
  bool sensor_records_lost;
  
  for(;;) {
    barrier_block(&send_barrier);
    barrier_reset(&send_barrier, NUM_SENSORS + 1);
    
    mutex_lock(&log_mutex);
      sensor_data_len = sizeof(sensor_data_t);
      while( volumeLogAppend(VOLUME_SENSORLOG, &storing_sensor_data, &sensor_data_len, &sensor_records_lost) != SUCCESS );
    mutex_unlock(&log_mutex);
    
    storing_sensor_data.seq_no++;
    led0Toggle();

    //tosthread_sleep(SAMPLING_PERIOD);
    barrier_block(&sense_barrier);
    barrier_reset(&sense_barrier, NUM_SENSORS + 1);
  }
}
void send_thread(void* arg) {
  storage_len_t sensor_data_len;
  
  for(;;) {
    tosthread_sleep(SENDING_PERIOD);

    while( volumeLogCurrentReadOffset(VOLUME_SENSORLOG) != volumeLogCurrentWriteOffset(VOLUME_SENSORLOG) ) {
      sensor_data_len = sizeof(sensor_data_t);
      mutex_lock(&log_mutex);
        while( volumeLogRead(VOLUME_SENSORLOG, sending_sensor_data, &sensor_data_len) != SUCCESS );
      mutex_unlock(&log_mutex);
      
      while( amRadioSend(AM_BROADCAST_ADDR, &send_msg, sizeof(sensor_data_t), AM_SENSOR_DATA_MSG) != SUCCESS );
      led1Toggle();
    }
    led2Toggle();
  }
}
