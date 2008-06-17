#include "tosthread.h"
#include "tosthread_amradio.h"
#include "tosthread_leds.h"
#include "tosthread_threadsync.h"
#include "tosthread_logstorage.h"
#include "tmote_onboard_sensors.h"
#include "StorageVolumes.h"
#include "lz.c"
#include "lz.h"

#define SAMPLING_PERIOD           100
#define SENDING_PERIOD             50
#define SENDING_INTERVAL           25
#define AM_SENSOR_DATA_MSG       0x25
#define NUM_RECORDS_TO_COMPRESS    50
#define NUM_SENSORS                 4
#define TOTAL_NUM_RECORDS_TO_SEND 500

//Data structure for storing sensor data
typedef nx_struct sensor_data {
  nx_uint32_t seq_no;
  nx_uint16_t hum;
  nx_uint16_t temp;
  nx_uint16_t tsr;
  nx_uint16_t par;
} sensor_data_t;

typedef nx_struct radio_data {
  nx_uint8_t taskNum;
  nx_uint16_t pktNum;
  nx_uint8_t more;
  nx_uint8_t data[0];
} radio_data_t;

//Initialize variables associated with each thread
tosthread_t humidity;
tosthread_t temperature;
tosthread_t total_solar;
tosthread_t photo_active;
tosthread_t store_handler;
tosthread_t send_handler;

message_t send_msg;
sensor_data_t storing_sensor_data;
mutex_t data_mutex;
mutex_t log_mutex;
barrier_t send_barrier;
barrier_t sense_barrier;

sensor_data_t compressing_sensor_data[NUM_RECORDS_TO_COMPRESS];

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
  
  storing_sensor_data.seq_no = 0;

  amRadioStart();
  led0Toggle();
  volumeLogErase(VOLUME_SENSORLOG);
  volumeLogSeek(VOLUME_SENSORLOG, SEEK_BEGINNING);
  led0Toggle();
  tosthread_create(&humidity, humidity_thread, NULL, 200);
  tosthread_create(&temperature, temperature_thread, NULL, 200);
  tosthread_create(&total_solar, total_solar_thread, NULL, 200);
  tosthread_create(&photo_active, photo_active_thread, NULL, 200);
  tosthread_create(&store_handler, store_thread, NULL, 200);
  tosthread_create(&send_handler, send_thread, NULL, 5000);
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

uint8_t taskNum = 0;

void send_thread(void* arg) {
  storage_len_t sensor_data_len;
  uint8_t numRecords = 0;
  uint8_t out[((NUM_RECORDS_TO_COMPRESS * sizeof(sensor_data_t) * 257 - 1) / 256) + 1 + 1];
  
  for(;;) {
    tosthread_sleep(SENDING_PERIOD);
    
    while( volumeLogCurrentReadOffset(VOLUME_SENSORLOG) != volumeLogCurrentWriteOffset(VOLUME_SENSORLOG) ) {
      sensor_data_len = sizeof(sensor_data_t);
      mutex_lock(&log_mutex);
        while( volumeLogRead(VOLUME_SENSORLOG, &(compressing_sensor_data[numRecords]), &sensor_data_len) != SUCCESS );
        numRecords++;
      mutex_unlock(&log_mutex);
      
      if (numRecords == NUM_RECORDS_TO_COMPRESS) {
        uint8_t pktNum = 0;
        uint16_t outsize = 0, sendsize = 0, sendindex = 0;
        radio_data_t *payload = NULL;
        
        outsize = LZ_Compress((void *)compressing_sensor_data, out, NUM_RECORDS_TO_COMPRESS * sizeof(sensor_data_t));
        
        while (outsize > 0) {
          if (outsize > (TOSH_DATA_LENGTH - sizeof(radio_data_t))) {
            sendsize = TOSH_DATA_LENGTH - sizeof(radio_data_t);
          } else {
            sendsize = outsize;
          }
          
          payload = (radio_data_t *) radioGetPayload(&send_msg, sizeof(radio_data_t) + sendsize);
          payload->taskNum = taskNum;
          payload->pktNum = pktNum;
          payload->more = ((outsize - sendsize) > 0) ? TRUE : FALSE;
          memcpy(payload->data, &(out[sendindex]), sendsize);
          
          while( amRadioSend(AM_BROADCAST_ADDR, &send_msg, sizeof(radio_data_t) + sendsize, AM_SENSOR_DATA_MSG) != SUCCESS );
          
          outsize -= sendsize;
          sendindex += sendsize;
          pktNum++;
          led1Toggle();
          tosthread_sleep(SENDING_INTERVAL);
        }
        
        taskNum++;
        pktNum = 0;
        numRecords = 0;
      }
    }
    
    //led2Toggle();
  }
}
