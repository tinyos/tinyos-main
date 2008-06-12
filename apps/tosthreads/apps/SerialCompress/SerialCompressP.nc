#include "lz.c"
#include "lz.h"

#define NUM_RECORDS_TO_COMPRESS 50

module SerialCompressP {
  uses {
    interface Boot;
    interface Leds;
    interface LogRead;
    interface LogWrite;
    interface SplitControl as SerialSplitControl;
    interface Receive;
    interface AMSend;
    interface AMPacket;
  }
}

implementation {
  typedef nx_struct serial_data {
    nx_uint32_t pktNum;
    nx_uint8_t data[0];
  } serial_data_t;

  serial_data_t *writeEntry;
  bool isBusy_writeEntry = FALSE;
  serial_data_t *readEntry;
  bool isBusy_readEntry = FALSE;

  uint16_t numRecords = 0;  
  uint16_t MAX_SERIAL_DATA_LENGTH = TOSH_DATA_LENGTH - sizeof(serial_data_t);
  uint32_t expectedPktNum = 0;
  uint32_t pktLoss = 0;
  //uint8_t in[NUM_RECORDS_TO_COMPRESS * MAX_SERIAL_DATA_LENGTH];
  //uint8_t out[((NUM_RECORDS_TO_COMPRESS * MAX_SERIAL_DATA_LENGTH * 257 - 1) / 256) + 1 + 1];
  uint8_t *in;
  uint8_t *out;

  message_t mesg;

  event void AMSend.sendDone(message_t *msg, error_t error) {}

  event void Boot.booted()
  {
    call Leds.set(7);
    writeEntry = (serial_data_t *)malloc(TOSH_DATA_LENGTH);
    readEntry = (serial_data_t *)malloc(TOSH_DATA_LENGTH);
    in = malloc(NUM_RECORDS_TO_COMPRESS * MAX_SERIAL_DATA_LENGTH);
    out = malloc(NUM_RECORDS_TO_COMPRESS * MAX_SERIAL_DATA_LENGTH * 2);
    while (call LogWrite.erase() != SUCCESS) {}
  }
  
  event message_t* Receive.receive(message_t *msg, void *msg_payload, uint8_t len)
  {
    if (isBusy_writeEntry == FALSE) {
      serial_data_t *payload = (serial_data_t *)msg_payload;
      
      writeEntry->pktNum = payload->pktNum;
      memcpy(writeEntry->data, payload->data, MAX_SERIAL_DATA_LENGTH);
      
      if (payload->pktNum == 0xFFFFFFFF) {
        uint8_t *p = (uint8_t *) call AMSend.getPayload(&mesg, 4);
        p[0] = (pktLoss >> 24) & 0xFF;
        p[1] = (pktLoss >> 16) & 0xFF;
        p[2] = (pktLoss >> 8) & 0xFF;
        p[3] = pktLoss & 0xFF;
        call AMSend.send(AM_BROADCAST_ADDR, &mesg, 4);
      } else if (payload->pktNum != expectedPktNum) {
        pktLoss += payload->pktNum - expectedPktNum;
        call Leds.led1Toggle();
      }
      expectedPktNum = payload->pktNum + 1;
      
      if (call LogWrite.append(writeEntry, TOSH_DATA_LENGTH) == SUCCESS) {
        isBusy_writeEntry = TRUE;
      }
    }
    
    return msg;
  }

  task void processLog()
  {
    if (call LogRead.currentOffset() < call LogWrite.currentOffset()) {
      if (isBusy_readEntry == FALSE) {
        if (call LogRead.read(readEntry, TOSH_DATA_LENGTH) == SUCCESS) {
          isBusy_readEntry = TRUE;
        } else {
          post processLog();
        }
      }
    }
  }
  
  task void readDoneTask()
  {
    memcpy(&(in[numRecords * MAX_SERIAL_DATA_LENGTH]), readEntry->data, MAX_SERIAL_DATA_LENGTH);
    numRecords++;
      
    if (numRecords == NUM_RECORDS_TO_COMPRESS) {
      call Leds.led2Toggle();
      LZ_Compress(in, out, NUM_RECORDS_TO_COMPRESS * MAX_SERIAL_DATA_LENGTH);
      numRecords = 0;
    }
      
    isBusy_readEntry = FALSE;
    post processLog();
  }
  
  event void LogRead.readDone(void* buf, storage_len_t len, error_t error)
  {
    if (error == SUCCESS) {
      post readDoneTask();
    } else {
      isBusy_readEntry = FALSE;
      post processLog();
    }
  }
  
  event void LogWrite.appendDone(void* buf, storage_len_t len, bool recordsLost, error_t error)
  {
    isBusy_writeEntry = FALSE;
    
    if (error == SUCCESS) {
      post processLog(); 
    }
  }
  
  event void LogWrite.eraseDone(error_t error)
  {
    if (error == SUCCESS) {
      while (call SerialSplitControl.start() != SUCCESS) {}
    } else {
      while (call LogWrite.erase() != SUCCESS) {}      
    }
  }

  event void LogRead.seekDone(error_t error) {}
  
  event void SerialSplitControl.startDone(error_t error)
  {
    if (error == SUCCESS) {
      call Leds.set(0);
    } else {
      while (call SerialSplitControl.start() != SUCCESS) {}
    }
  }
  
  event void SerialSplitControl.stopDone(error_t error) {}
  event void LogWrite.syncDone(error_t error) {}
}
