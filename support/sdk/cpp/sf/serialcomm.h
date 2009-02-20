/*
 * Copyright (c) 2007, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions 
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright 
 *   notice, this list of conditions and the following disclaimer in the 
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names 
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
/**
 * @author Philipp Huppertz <huppertz@tkn.tu-berlin.de>
 */

#ifndef SERIALCOMM_H
#define SERIALCOMM_H

#include "basecomm.h"
#include "sfpacket.h"
#include "packetbuffer.h"
#include "sharedinfo.h"

#include <sys/select.h>
#include <pthread.h>
#include <termios.h>
#include <string>
#include <sstream>
#include <iostream>

// #define DEBUG_SERIALCOMM
// #define DEBUG_RAW_SERIALCOMM

#undef DEBUG
#ifdef DEBUG_SERIALCOMM
#include <iostream>
#define DEBUG(message) std::cout << message << std::endl;
#else
#define DEBUG(message)
#endif


class SerialComm : public BaseComm
{

    /** Constants **/
protected:
    // max serial MTU
    static const int maxMTU = (SFPacket::cMaxPacketLength+1)*2;
    // min serial MTU
    static const int minMTU = 4;
    // byte count of serial header
    static const int serialHeaderBytes = 5;
    // byte offset of type field
    static const int typeOffset = 0;
    // byte offset of sequence number field
    static const int seqnoOffset = 1;
    // byte offset of payload field
    static const int payloadOffset = 2;
    // timeout for acks in s
    static const int ackTimeout = 1000 * 1000 * 200;
    // max. reties for packets from pc to node
    static const int maxRetries = 25;

    // how many bytes do we attempt to read from the serial line in one go?
    static const int rawReadBytes = 20;

    enum rx_states_t {
        WAIT_FOR_SYNC,
        IN_SYNC,
        ESCAPED
    };
    
    /** Member vars */
protected:
    /* pthread for serial reading */
    pthread_t readerThread;

    bool readerThreadRunning;

    /* pthread for serial writing */
    pthread_t writerThread;

    bool writerThreadRunning;

    // thread safe ack
    typedef struct
    {
        // mutex lock for any of this vars
        pthread_mutex_t lock;
        // notempty cond
        pthread_cond_t received;
    } ackCondition_t;

    ackCondition_t ack;

    /* raw read buffer */
    struct rawFifo_t {
        char queue[maxMTU];
        int head;
        int tail;
    };

    rawFifo_t rawFifo;
    
    /* reference to read packet buffer */
    PacketBuffer &readBuffer;

    /* reference to write packet buffer */
    PacketBuffer &writeBuffer;

    /* number of dropped (read) packets */
    int droppedReadPacketCount;

    /* number of dropped (write) packets */
    int droppedWritePacketCount;

    /* number of read packets */
    int readPacketCount;

    /* number of written packets */
    int writtenPacketCount;

    /* number of bad packets read from serial line, counts resynchronizations! */
    int badPacketCount;

    /* sum retry attempts for all packets */
    int sumRetries;
    
    /* device port of this sf */
    std::string device;

    /* baudrate of connected device */
    int baudrate;

    /* read fd set */
    fd_set rfds;

    /* write fd set */
    fd_set wfds;

    /* fd for reading from serial device */
    int serialReadFD;

    /* fd for writing to serial device */
    int serialWriteFD;

    /* seqno for serial data packets */
    int seqno;

    /* indicates that an error occured */
    bool errorReported;

    /* error message of reportError call */
    std::ostringstream errorMsg;
    
    /* for noticing the parent thread of cancelation */
    sharedControlInfo_t &control;
    
/** Member functions */

    /* needed to start pthreads */
    friend void* readSerialThread(void* ob);
    friend void* writeSerialThread(void* ob);

private:
    /* do not allow standard constructor */
    SerialComm();

protected:
    char nextRaw();
    
    /* claculates crc byte-wise */
    inline static uint16_t byteCRC(uint8_t byte, uint16_t crc) {
        crc = (uint8_t)(crc >> 8) | (crc << 8);
        crc ^= byte;
        crc ^= (uint8_t)(crc & 0xff) >> 4;
        crc ^= crc << 12;
        crc ^= (crc & 0xff) << 5;
        return crc;
    }
    
    inline static uint16_t calcCRC(uint8_t *bytes, uint16_t len) {
        uint16_t crc = 0;
        for(unsigned i = 0; i < len; i++) {
            crc = SerialComm::byteCRC(bytes[i], crc);
        }
        return crc;
    }

    inline static uint16_t checkCrc(uint8_t *bytes, uint16_t count) {
        bool crcOk = false;
        if(count > 2) {
            uint16_t crc = calcCRC(bytes, count - 2);
            uint16_t packetCrc = (bytes[count-1] << 8) | bytes[count-2];
            if(crc == packetCrc) crcOk = true;
        }
        return crcOk;
    }

    /* HDLC encode (byte stuff) count bytes from buffer from into buffer to.
     * to must be at least count * 2 bytes large. Returns the number of bytes
     * written into to.
     */
    int hdlcEncode(int count, const char* from, char *to);
    
    /**
     *  try to read at least count bytes in one go, but may read up to maxCount bytes.
     */
    virtual int readFD(int fd, char *buffer, int count, int maxCount, int *err);

    /* enables byte escaping. overwrites method from base class.*/
    virtual int writeFD(int fd, const char *buffer, int count, int *err);

    /* reads a packet (blocking) */
    bool readPacket(SFPacket &pPacket);

    /* writes a packet to serial source */
    bool writePacket(SFPacket &pPacket);

    /* returns tcflag of requested baudrate */
    static tcflag_t parseBaudrate(int requested);

    int reportError(const char *msg, int result);

    /* checks for messages from node - producer thread */
    void readSerial();

    /* write messages to serial / node - consumer thread */
    void writeSerial();
    
public:
    SerialComm(const char* pDevice, int pBaudrate, PacketBuffer &pReadBuffer, PacketBuffer &pWriteBuffer,  sharedControlInfo_t& pControl);

    ~SerialComm();

    /* cancels all running threads */
    void cancel();

    std::string getDevice() const;

    int getBaudRate() const;

    void reportStatus(std::ostream& os);

    /* returns if error occurred */
    bool isErrorReported() { return errorReported; }
};

#endif
