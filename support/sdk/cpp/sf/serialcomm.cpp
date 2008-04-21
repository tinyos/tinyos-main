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

#include "serialcomm.h"
#include "sharedinfo.h"

#include <ctime>
#include <cstdlib>
#include <iostream>
#include <fcntl.h>
#include <termios.h>
#include <pthread.h>
#include <sstream>
#include <sys/time.h>
#include <errno.h>

using namespace std;

/* forward declarations of pthrad helper functions*/
void* readSerialThread(void*);
void* writeSerialThread(void*);

tcflag_t SerialComm::parseBaudrate(int requested)
{
    int baudrate;

    switch (requested)
    {
#ifdef B50
    case 50:
        baudrate = B50;
        break;
#endif
#ifdef B75

    case 75:
        baudrate = B75;
        break;
#endif
#ifdef B110

    case 110:
        baudrate = B110;
        break;
#endif
#ifdef B134

    case 134:
        baudrate = B134;
        break;
#endif
#ifdef B150

    case 150:
        baudrate = B150;
        break;
#endif
#ifdef B200

    case 200:
        baudrate = B200;
        break;
#endif
#ifdef B300

    case 300:
        baudrate = B300;
        break;
#endif
#ifdef B600

    case 600:
        baudrate = B600;
        break;
#endif
#ifdef B1200

    case 1200:
        baudrate = B1200;
        break;
#endif
#ifdef B1800

    case 1800:
        baudrate = B1800;
        break;
#endif
#ifdef B2400

    case 2400:
        baudrate = B2400;
        break;
#endif
#ifdef B4800

    case 4800:
        baudrate = B4800;
        break;
#endif
#ifdef B9600

    case 9600:
        baudrate = B9600;
        break;
#endif
#ifdef B19200

    case 19200:
        baudrate = B19200;
        break;
#endif
#ifdef B38400

    case 38400:
        baudrate = B38400;
        break;
#endif
#ifdef B57600

    case 57600:
        baudrate = B57600;
        break;
#endif
#ifdef B115200

    case 115200:
        baudrate = B115200;
        break;
#endif
#ifdef B230400

    case 230400:
        baudrate = B230400;
        break;
#endif
#ifdef B460800

    case 460800:
        baudrate = B460800;
        break;
#endif
#ifdef B500000

    case 500000:
        baudrate = B500000;
        break;
#endif
#ifdef B576000

    case 576000:
        baudrate = B576000;
        break;
#endif
#ifdef B921600

    case 921600:
        baudrate = B921600;
        break;
#endif
#ifdef B1000000

    case 1000000:
        baudrate = B1000000;
        break;
#endif
#ifdef B1152000

    case 1152000:
        baudrate = B1152000;
        break;
#endif
#ifdef B1500000

    case 1500000:
        baudrate = B1500000;
        break;
#endif
#ifdef B2000000

    case 2000000:
        baudrate = B2000000;
        break;
#endif
#ifdef B2500000

    case 2500000:
        baudrate = B2500000;
        break;
#endif
#ifdef B3000000

    case 3000000:
        baudrate = B3000000;
        break;
#endif
#ifdef B3500000

    case 3500000:
        baudrate = B3500000;
        break;
#endif
#ifdef B4000000

    case 4000000:
        baudrate = B4000000;
        break;
#endif

    default:
        baudrate = 0;
    }
    return baudrate;
}

SerialComm::SerialComm(const char* pDevice, int pBaudrate, PacketBuffer &pReadBuffer, PacketBuffer &pWriteBuffer, sharedControlInfo_t& pControl) : readBuffer(pReadBuffer), writeBuffer(pWriteBuffer), droppedReadPacketCount(0), droppedWritePacketCount(0), readPacketCount(0), writtenPacketCount(0), badPacketCount(0), sumRetries(0), device(pDevice), baudrate(pBaudrate), serialReadFD(-1), serialWriteFD(-1), errorReported(false), errorMsg(""), control(pControl)
{
    writerThreadRunning = false;
    readerThreadRunning = false;
    rawFifo.head = rawFifo.tail = 0;
    tcflag_t baudflag = parseBaudrate(pBaudrate);

    srand ( time(NULL) );
    seqno = rand();
    FD_ZERO(&rfds);
    FD_ZERO(&wfds);

    serialReadFD = open(device.c_str(), O_RDONLY | O_NOCTTY | O_NONBLOCK);
    serialWriteFD = open(device.c_str(), O_WRONLY | O_NOCTTY);

    if (((serialReadFD < 0) || (serialWriteFD < 0) || (!baudflag)) && !(errorReported == true))
    {
        ostringstream msg;
        msg << "could not open device = " << pDevice << " with baudrate = " << pBaudrate;
        reportError(msg.str().c_str() ,-1);
    }

    /* Serial port setting */
    struct termios newtio;
    memset(&newtio, 0, sizeof(newtio));
    newtio.c_cflag = CS8 | CLOCAL | CREAD;
    newtio.c_iflag = IGNPAR | IGNBRK;
    cfsetispeed(&newtio, baudflag);
    cfsetospeed(&newtio, baudflag);

    /* Raw output_file */
    newtio.c_oflag = 0;

    if ((tcflush(serialReadFD, TCIFLUSH) >= 0 && tcsetattr(serialReadFD, TCSANOW, &newtio) >= 0)
            && (tcflush(serialWriteFD, TCIFLUSH) >= 0 && tcsetattr(serialWriteFD, TCSANOW, &newtio) >= 0)
            && !errorReported)
    {
        DEBUG("SerialComm::SerialComm : opened device "<< pDevice << " with baudrate = " << pBaudrate)
    }
    else
    {
        close(serialReadFD);
        close(serialWriteFD);
        if (!errorReported)
        {
            ostringstream msg;
            msg << "could not set ioflags for opened device = " << pDevice;
            reportError(msg.str().c_str(),-1);
        }
    }

    pthread_mutex_init(&ack.lock, NULL);
    pthread_cond_init(&ack.received, NULL);

    if (!errorReported)
    {
        // start thread for reading from serial line
        if (reportError("SerialComm::SerialComm : pthread_create( &readerThread, NULL, readSerialThread, this)", pthread_create( &readerThread, NULL, readSerialThread, this)) == 0)
            readerThreadRunning = true;
        // start thread for writing to serial line
        if (reportError("SerialComm::SerialComm : pthread_create( &writerThread, NULL, writeSerialThread, this)", pthread_create( &writerThread, NULL, writeSerialThread, this)) == 0)
            writerThreadRunning = true;
    }
}


SerialComm::~SerialComm()
{
    cancel();

    pthread_mutex_destroy(&ack.lock);
    pthread_cond_destroy(&ack.received);

    if(serialReadFD > 2) close(serialReadFD);
    if(serialWriteFD > 2) close(serialWriteFD);
}

int SerialComm::hdlcEncode(int count, const char* from, char *to) {
    int offset = 0;
    for(int i = 0; i < count; i++) {
        if (from[i] == SYNC_BYTE || from[i] == ESCAPE_BYTE)
        {
            to[offset++] = ESCAPE_BYTE;
            to[offset++] = from[i] ^ 0x20;
        }
        else {
            to[offset++] = from[i];
        }
    }
    return offset;
}

int SerialComm::writeFD(int fd, const char *buffer, int count, int *err)
{
    int cnt = 0;
    /*
    FD_SET(serialWriteFD, &wfds);
    if(select(serialWriteFD + 1, NULL, &wfds, NULL, NULL) < 0) {
        return -1;
    }
    FD_CLR(serialWriteFD, &wfds);
     */
    int tmpCnt = BaseComm::writeFD(fd, buffer, count, err);
    if (tmpCnt < 0) {
        *err = errno;
        return tmpCnt;
    }
    else {
        cnt += tmpCnt;
    }
    return cnt;
}


/* Work around buggy usb serial driver (returns 0 when no data is
   available, independent of the blocking/non-blocking mode) */
int SerialComm::readFD(int fd, char *buffer, int count, int maxCount, int *err)
{
    int cnt = 0;
    timeval tvold;
    timeval tv;
    unsigned to = (10000000 / baudrate) * count; // time out in usec
    tvold.tv_sec = to / 1000000;
    tvold.tv_usec = to % 1000000;
    while (cnt == 0)
    {
        // no FD_ZERO here because of performance issues. It is done in constructor...
        FD_SET(serialReadFD, &rfds);
        if (select(serialReadFD + 1, &rfds, NULL, NULL, NULL) < 0) {
            return -1;
        }
        FD_CLR(serialReadFD, &rfds);
        tv = tvold;
        select(0, NULL, NULL, NULL, &tv);
        int tmpCnt = read(fd, buffer, maxCount);
        if (tmpCnt < 0) {
            *err = errno;
            return tmpCnt;
        }
        else {
            cnt += tmpCnt;
        }
    }
    return cnt;
}

char SerialComm::nextRaw() {
    char nextByte = 0;
    int err = 0;
    if(rawFifo.tail < rawFifo.head) {
        nextByte = rawFifo.queue[rawFifo.tail++];
    }
    else {
        // fifo empty -- need to get some bytes
        rawFifo.tail = 0;
        rawFifo.head = readFD(serialReadFD, rawFifo.queue, rawReadBytes, maxMTU-1, &err);
        if(rawFifo.head < 0) {
            close(serialReadFD);
            close(serialWriteFD);
            serialReadFD = -1;
            serialWriteFD = -1;
            errno = err;
        }
        reportError("SerialComm::nextRaw: readFD(serialReadFD, rawFifo.queue, rawReadBytes, maxMTU-1)",
                    rawFifo.head);
        nextByte = rawFifo.queue[rawFifo.tail++];
    }
    return nextByte;
}

/* reads packet */
bool SerialComm::readPacket(SFPacket &pPacket)
{
    bool sync = false;
    bool escape = false;
    bool completePacket = false;
    int count = 0;
    uint16_t crc = 0;
    char buffer[maxMTU];
    while(!completePacket)
    {
        buffer[count] = nextRaw();

        if(sync && (count == 1) && (buffer[count] == SYNC_BYTE)) {
            DEBUG("SerialComm::readPacket double sync byte");
            sync = false;
            escape = false;
            count = 1;
            crc = 0;
            buffer[0] = SYNC_BYTE;
        }
        
        if (!sync)
        {
            // wait for sync
            if (buffer[0] == SYNC_BYTE)
            {
                sync = true;
                escape = false;
                count = 1;
                crc = 0;
            }
        }
        else if (count >= maxMTU)
        {
            DEBUG("SerialComm::readPacket : frame too long - size = " << count << " : resynchronising")
            sync = false;
            escape = false;
            count = crc = 0;
	    badPacketCount++;
        }
        else if (escape)
        {
            if (buffer[count] == SYNC_BYTE)
            {
                DEBUG("SerialComm::readPacket : resynchronising")
                sync = false;
                escape = false;
                count = crc = 0;
		badPacketCount++;
            }
            else
            {
                buffer[count] ^= 0x20;
                if (count > 3)
                {
                    crc = SerialComm::byteCRC(buffer[count-3], crc);
                }
                ++count;
                escape = false;
            }
        }
        else if (buffer[count] == ESCAPE_BYTE)
        {
            // next byte is escaped
            escape = true;
        }
        else if (buffer[count] == SYNC_BYTE)
        {
            // calculate last crc byte
            if (count > 3)
            {
                crc = SerialComm::byteCRC(buffer[count-3], crc);
            }
            uint16_t packetCRC = (buffer[count - 2] & 0xff) | ((buffer[count - 1] << 8) & 0xff00);
            if (count < minMTU)
            {
                DEBUG("SerialComm::readPacket : frame too short - size = " << count << " : resynchronising ")
                sync = false;
                escape = false;
                count = crc = 0;
		badPacketCount++;
            }
            else if (crc != packetCRC)
            {
                DEBUG("SerialComm::readPacket : bad crc - calculated crc = " << crc << " packet crc = " << packetCRC << " : resynchronising " )
                sync = false;
                escape = false;
                count = crc = 0;
		badPacketCount++;
            }
            else
            {
                pPacket.setType(buffer[typeOffset]);
                pPacket.setSeqno(buffer[seqnoOffset]);
                switch (buffer[typeOffset])
                {
                case SF_ACK:
                    break;
                case SF_PACKET_NO_ACK:
                case SF_PACKET_ACK:
                    // buffer / payload
                    // FIXME: strange packet format!? because seqno is not really defined - missing :(
                    pPacket.setPayload(&buffer[payloadOffset]-1, count+1+1 - serialHeaderBytes);
                    break;
                default:
                    DEBUG("SerialComm::readPacket : unknown packet type = " << static_cast<uint16_t>(buffer[typeOffset] & 0xff))
                    ;
                }
                completePacket = true;
#ifdef DEBUG_RAW_SERIALCOMM

                DEBUG("SerialComm::readPacket : raw data >>")
                for (int j=0; j <= count; j++)
                {
                    cout << std::hex << static_cast<uint16_t>(buffer[j] & 0xff) << " " << std::dec;
                }
                cout << endl;
                cout << "as payload >> " << endl;
                const char* ptr = pPacket.getPayload();
                for (int j=0; j < pPacket.getLength(); j++)
                {
                    cout << std::hex << static_cast<uint16_t>(ptr[j] & 0xff) << " " << std::dec;
                }
                cout << endl;
#endif

            }
        }
        else
        {
            if (count > 3)
            {
                crc = SerialComm::byteCRC(buffer[count-3], crc);
            }
            ++count;
        }
    }
    return true;
}


/* writes packet */
bool SerialComm::writePacket(SFPacket &pPacket)
{
    char type, byte = 0;
    uint16_t crc = 0;
    char buffer[2*pPacket.getLength() + 20];
    int offset = 0;
    int err = 0;
    int written = 0;
    
    // put SFD into buffer 
    buffer[offset++] = SYNC_BYTE;

    // packet type
    byte = type = pPacket.getType();
    crc = byteCRC(byte, crc);
    offset += hdlcEncode(1, &byte, buffer + offset);

    // seqno
    byte = pPacket.getSeqno();
    crc = byteCRC(byte, crc);
    offset += hdlcEncode(1, &byte, buffer + offset);
    switch (type)
    {
    case SF_ACK:
        break;
    case SF_PACKET_NO_ACK:
    case SF_PACKET_ACK:
        // compute crc
        for(int i = 0; i < pPacket.getLength(); i++) {
            crc = byteCRC(pPacket.getPayload()[i], crc);
        }
        offset += hdlcEncode(pPacket.getLength(), pPacket.getPayload(), buffer + offset);
        break;
    default:
        return false;
    }

    // crc two bytes
    byte = crc & 0xff;
    offset += hdlcEncode(1, &byte, buffer + offset);
    byte = (crc >> 8) & 0xff;
    offset += hdlcEncode(1, &byte, buffer + offset);
    
    // put SFD into buffer
    buffer[offset++] = SYNC_BYTE;
    written = writeFD(serialWriteFD, buffer, offset, &err);
    if(written < 0) {
        if(err != EINTR) {
            close(serialReadFD);
            serialReadFD = -1;
            close(serialWriteFD);
            serialWriteFD = -1;
            errno = err;
            reportError("SerialComm::writePacket failed",-1);
            return false;
        }
    }
    else if(written < offset) {
        DEBUG("SerialComm::writePacket failed");
        return false;
    }
    return true;
}

string SerialComm::getDevice() const
{
    return device;
}

int SerialComm::getBaudRate() const
{
    return baudrate;
}

/* helper function to start serial reader pthread */
void* readSerialThread(void* ob)
{
    static_cast<SerialComm*>(ob)->readSerial();
    return NULL;
}

/* reads from connected clients */
void SerialComm::readSerial()
{
    while (true)
    {
        SFPacket packet;
        readPacket(packet);
        switch (packet.getType())
        {
        case SF_ACK:
            // successful delivery
            // FIXME: seqnos are not implemented on the node !
            pthread_cond_signal(&ack.received);
            break;
        case SF_PACKET_ACK:
            {
                // put ack in front of queue
                SFPacket ack(SF_ACK, packet.getSeqno());
                writeBuffer.enqueueFront(ack);
            }
        case SF_PACKET_NO_ACK:
            // do nothing - fall through
        default:
            if (!readBuffer.isFull())
            {
                ++readPacketCount;
                // put silently into buffer...
                readBuffer.enqueueBack(packet);
            }
            else
            {
                while(readBuffer.isFull()) {
                    readBuffer.dequeue();
                    ++droppedReadPacketCount;
                }
                readBuffer.enqueueBack(packet);
                // DEBUG("SerialComm::readSerial : dropped packet")
            }
        }
    }
}

/* helper function to start serial writer pthread */
void* writeSerialThread(void* ob)
{
    static_cast<SerialComm*>(ob)->writeSerial();
    return NULL;
}

/* writes to serial/node */
void SerialComm::writeSerial()
{
    SFPacket packet;
    bool retry = false;
    int retryCount = 0;
    long long timeout;
    
    while (true)
    {
        if (!retry)
        {
            packet = writeBuffer.dequeue();
        }
        switch (packet.getType())
        {
        case SF_ACK:
            // successful delivery
            if (!writePacket(packet))
            {
                DEBUG("SerialComm::writeSerial : writePacket failed (SF_ACK)")
                reportError("SerialComm::writeSerial : writePacket(SF_ACK)", -1);
            }
            break;
        case SF_PACKET_ACK:
            // do nothing - fall through
        case SF_PACKET_NO_ACK:
            // do nothing - fall through
        default:
            if (!retry)
                ++writtenPacketCount;
            // FIXME: this is the only currently supported type by the mote
            packet.setType(SF_PACKET_ACK);
            if (!writePacket(packet))
            {
                DEBUG("SerialComm::writeSerial : writePacket failed (SF_PACKET)")
                reportError("SerialComm::writeSerial : writeFD(SF_PACKET)", -1);
            }
            // wait for ack...
            struct timeval currentTime;
            struct timespec ackTime;
            timeout = (long long)ackTimeout * (retryCount + 1);
            
            pthread_testcancel();
            pthread_mutex_lock(&ack.lock);

            gettimeofday(&currentTime, NULL);
            ackTime.tv_sec = currentTime.tv_sec;
            ackTime.tv_nsec = currentTime.tv_usec * 1000;

	    ackTime.tv_sec  +=  timeout / (1000*1000*1000);
	    ackTime.tv_nsec += timeout % (1000*1000*1000);

            pthread_cleanup_push((void(*)(void*)) pthread_mutex_unlock, (void *) &ack.lock);
            int retval = pthread_cond_timedwait(&ack.received, &ack.lock, &ackTime);
            if (!((retryCount < maxRetries) && (retval == ETIMEDOUT)))
            {
		if (retryCount >= maxRetries) ++droppedWritePacketCount;
                retry = false;
                retryCount = 0;
            }
            else
            {
                ++retryCount;
                retry = true;
                DEBUG("SerialComm::writeSerial : packet retryCount = " << retryCount);
		++sumRetries;
            }
            // removes the cleanup handler and executes it (unlock mutex)
            pthread_cleanup_pop(1);         }
    }
}

/* cancels all running threads */
void SerialComm::cancel()
{
    pthread_t callingThread = pthread_self();
    if(readerThreadRunning && pthread_equal(callingThread, readerThread))
    {
        DEBUG("SerialComm::cancel : by readerThread")
        pthread_detach(readerThread);
        if (writerThreadRunning)
        {
            pthread_cancel(writerThread);
            DEBUG("SerialComm::cancel : writerThread canceled, joining")
            pthread_join(writerThread, NULL);
            writerThreadRunning = false;
        }
        readerThreadRunning = false;
	pthread_cond_signal(&control.cancel);
        pthread_exit(NULL);
    }
    else if(writerThreadRunning && pthread_equal(callingThread, writerThread))
    {
        DEBUG("SerialComm::cancel : by writerThread")
        pthread_detach(writerThread);
        if (readerThreadRunning)
        {
            pthread_cancel(readerThread);
            DEBUG("SerialComm::cancel : readerThread canceled, joining")
            pthread_join(readerThread, NULL);
            readerThreadRunning = false;
        }
        writerThreadRunning = false;
	pthread_cond_signal(&control.cancel);
        pthread_exit(NULL);
    }
    else
    {
        DEBUG("SerialComm::cancel : by other thread")
        if (readerThreadRunning)
        {
            pthread_cancel(readerThread);
            DEBUG("SerialComm::cancel : readerThread canceled, joining")
            pthread_join(readerThread, NULL);
            readerThreadRunning = false;
        }
        if (writerThreadRunning)
        {
            pthread_cancel(writerThread);
            DEBUG("SerialComm::cancel : writerThread canceled, joining")
            pthread_join(writerThread, NULL);
            writerThreadRunning = false;
        }
	pthread_cond_signal(&control.cancel);
    }
}

/* reports error */
int SerialComm::reportError(const char *msg, int result)
{
    if ((result < 0) && (!errorReported))
    {
        errorMsg << "error : SF-Server ( SerialComm on device = " << device << " ) : "
        << msg << " ( result = " << result << " )" << endl
        << "error-description : " << strerror(errno) << endl;

	cerr << errorMsg.str();
        errorReported = true;
        cancel();
    }
    return result;
}

/* prints out status */
void SerialComm::reportStatus(ostream& os)
{
    os << "SF-Server ( SerialComm on device " << device << " ) : "
       << "baudrate = " << baudrate
       << " , packets read = " << readPacketCount
       << " ( dropped = " << droppedReadPacketCount 
       << ", bad = " << badPacketCount << " )"
       << " , packets written = " << writtenPacketCount
       << " ( dropped = " << droppedWritePacketCount 
       << ", total retries: " << sumRetries << " )"
       << endl;
}
