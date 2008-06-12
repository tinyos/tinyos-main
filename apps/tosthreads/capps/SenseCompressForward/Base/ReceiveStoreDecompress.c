#include "tosthread.h"
#include "tosthread_amradio.h"
#include "tosthread_amserial.h"
#include "tosthread_leds.h"
#include "tosthread_threadsync.h"
#include "tosthread_logstorage.h"
#include "StorageVolumes.h"
#include "lz.c"
#include "lz.h"

#define SENDING_PERIOD              1
#define AM_SENSOR_DATA_MSG       0x25
#define NUM_RECORDS_TO_COMPRESS    50

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

typedef struct log_entry {
  uint8_t taskNum;
  uint16_t pktNum;
  uint8_t more;
  uint8_t srcNodeId;
  uint8_t len;
  uint8_t data[TOSH_DATA_LENGTH - sizeof(radio_data_t)];
} log_entry_t;

//Initialize variables associated with each thread
tosthread_t receive_handler;
tosthread_t decompress_handler;

mutex_t log_mutex;

void receive_thread(void* arg);
void decompress_thread(void* arg);

void tosthread_main(void* arg) {
  mutex_init(&log_mutex);
  amRadioStart();
amSerialStart();
  led0Toggle();
  volumeLogErase(VOLUME_SENSORLOG);
  volumeLogSeek(VOLUME_SENSORLOG, SEEK_BEGINNING);
  led0Toggle();
  tosthread_create(&receive_handler, receive_thread, NULL, 1000);
  tosthread_create(&decompress_handler, decompress_thread, NULL, 5000);
}

void receive_thread(void* arg) {
  message_t mesg;
  log_entry_t entry;
  bool data_lost;
  uint8_t payload_len;
  storage_len_t entry_len;
  radio_data_t *payload;
  
  for (;;) {
    if (amRadioReceive(&mesg, 0, AM_SENSOR_DATA_MSG) == SUCCESS) {
      payload_len = radioGetPayloadLength(&mesg);
      payload = (radio_data_t *)radioGetPayload(&mesg, payload_len);
      
      entry.taskNum = payload->taskNum;
      entry.pktNum = payload->pktNum;
      entry.more = payload->more;
      entry.srcNodeId = amRadioGetSource(&mesg) & 0xFF;
      entry.len = payload_len - sizeof(radio_data_t);
      memcpy(entry.data, payload->data, entry.len);

/*    
      {
        int i;
        for (i = 0; i < entry.len; i++) {
          entry.data[i] = payload->data[i];
        }
      }
*/
      
      entry_len = sizeof(log_entry_t);
      mutex_lock(&log_mutex);
        while( volumeLogAppend(VOLUME_SENSORLOG, &entry, &entry_len, &data_lost) != SUCCESS );
      mutex_unlock(&log_mutex);
    }
  }
}

void decompress_thread(void* arg) {
  storage_len_t entry_len;
  log_entry_t entry;
  uint16_t insize[2] = {0, 0};
  uint8_t taskNum[2] = {0, 0};
  uint16_t pktNum[2] = {0, 0};
  uint8_t in[2][((NUM_RECORDS_TO_COMPRESS * sizeof(sensor_data_t) * 257 - 1) / 256) + 1 + 1];
  uint8_t out[NUM_RECORDS_TO_COMPRESS * sizeof(sensor_data_t)];
//  uint32_t pktLoss[2] = {0, 0};
  bool isComplete[2];

  for(;;) {
    tosthread_sleep(SENDING_PERIOD);
    
    while( volumeLogCurrentReadOffset(VOLUME_SENSORLOG) != volumeLogCurrentWriteOffset(VOLUME_SENSORLOG) ) {
      entry_len = sizeof(log_entry_t);
      mutex_lock(&log_mutex);
        while( volumeLogRead(VOLUME_SENSORLOG, &entry, &entry_len) != SUCCESS );
      mutex_unlock(&log_mutex);
      
      if (entry.pktNum == 0) {
        led2Toggle();
        
        taskNum[entry.srcNodeId] = entry.taskNum;
        pktNum[entry.srcNodeId] = 1;
        isComplete[entry.srcNodeId] = TRUE;
        memcpy(in[entry.srcNodeId], entry.data, entry.len);
        insize[entry.srcNodeId] = entry.len;
      } else {
        led0Toggle();
        if (entry.taskNum == taskNum[entry.srcNodeId] && entry.pktNum == pktNum[entry.srcNodeId]) {
//          uint16_t startIndex = (TOSH_DATA_LENGTH - sizeof(radio_data_t)) * pktNum[entry.srcNodeId];
//          memcpy(&(in[entry.srcNodeId][startIndex]), entry.data, entry.len);
//          memcpy(&(in[entry.srcNodeId][insize[entry.srcNodeId] - 1]), entry.data, entry.len);

          {
            int i;
            for (i = 0; i < entry.len; i++) {
              (in[entry.srcNodeId])[insize[entry.srcNodeId] + i] = entry.data[i];
            }
          }

          insize[entry.srcNodeId] += entry.len;
          pktNum[entry.srcNodeId]++;
          
          if (entry.more == FALSE && isComplete[entry.srcNodeId] == TRUE) {
            led1Toggle();

            LZ_Uncompress(in[entry.srcNodeId], out, insize[entry.srcNodeId]);
  
/*
            {
              int tempinsize = insize[entry.srcNodeId], sendSize = 0, sendIndex = 0;
              void *serialMsg_payload;
              message_t serialMsg;
              
              while (tempinsize > 0) {
                if (tempinsize > TOSH_DATA_LENGTH) {
                  sendSize = TOSH_DATA_LENGTH;
                } else {
                  sendSize = tempinsize;
                }
                
                serialMsg_payload = serialGetPayload(&serialMsg, sendSize);
                memcpy(serialMsg_payload, &(in[entry.srcNodeId][sendIndex]), sendSize);
                while( amSerialSend(AM_BROADCAST_ADDR, &serialMsg, sendSize, 0) != SUCCESS );
                sendIndex += sendSize;
                tempinsize -= sendSize;
              }
            }
*/
/*
            {
              int i;
              for (i = 0; i < NUM_RECORDS_TO_COMPRESS; i++) {
                message_t serialMsg;
                void *serialMsg_payload = serialGetPayload(&serialMsg, sizeof(sensor_data_t));
                memcpy(serialMsg_payload, &(out[i * sizeof(sensor_data_t)]), sizeof(sensor_data_t));
                while( amSerialSend(AM_BROADCAST_ADDR, &serialMsg, sizeof(sensor_data_t), 0) != SUCCESS );
              }
            }
*/
            pktNum[entry.srcNodeId] = 0;
          }
        } else {
          isComplete[entry.srcNodeId] = FALSE;
          led0Toggle();
        }
      }
    }
  }
}
