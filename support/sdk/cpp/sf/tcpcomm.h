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


#ifndef TCPCOMM_H
#define TCPCOMM_H

#include "sfpacket.h"
#include "packetbuffer.h"
#include "basecomm.h"
#include "sharedinfo.h"

#include <pthread.h>
#include <set>
#include <string>
#include <sstream>

// #define DEBUG_TCPCOMM

#undef DEBUG
#ifdef DEBUG_TCPCOMM
#include <iostream>
#define DEBUG(message) std::cout << message << std::endl;
#else
#define DEBUG(message) 
#endif

class TCPComm : public BaseComm
{

    /** Member vars */
protected:
    /* pthread for tcp client connection handling */
    pthread_t serverThread;

    bool serverThreadRunning;

    /* pthread for tcp client reading */
    pthread_t readerThread;

    bool readerThreadRunning;

    /* pthread for tcp client writing */
    pthread_t writerThread;

    bool writerThreadRunning;

    typedef std::set<int> FD_t;

    // thread safe shared info about connected clients
    typedef struct
    {
        /* mutex to protect clientCount and clientFDs */
        pthread_mutex_t countlock;
	/* mutex to protect wakeup condiation */
	pthread_mutex_t sleeplock;        
	/* wakeup condition which is siganled if clients are connected */
        pthread_cond_t wakeup;
        /* number of connected clients */
        int count;
        /* container for client stuff */
        FD_t FDs;
    } sharedClientInfo_t;

    /* information about clients */
    sharedClientInfo_t clientInfo;

    /* number of read packets */
    int readPacketCount;

    /* number of written packets */
    int writtenPacketCount;

    /* port of this sf */
    int port;

    /* file descriptor for server port on local machine */
    int serverFD;

    /* pipe fd pair to inform client reader thread of new clients */
    int pipeWriteFD;
    int pipeReadFD;
    
    /* reference to read packet buffer */
    PacketBuffer &readBuffer;    

    /* reference to write packet buffer */
    PacketBuffer &writeBuffer;
       
    /* indicates that an error occured */
    bool errorReported;

    /* error message of reportError call */
    std::ostringstream errorMsg;

    /* for noticing the parent thread of cancelation */
    sharedControlInfo_t &control;

    /** Member functions */

    /* needed to start pthreads */
    friend void* checkClientsThread(void* ob);
    friend void* readClientsThread(void* ob);
    friend void* writeClientsThread(void* ob);

private:
    /* disable standard constructor */
    TCPComm();

protected:
    /* performs blocking write on fd */
    virtual int writeFD(int fd, const char *buffer, int count, int *err);

    /* checks SF client protocol version */
    bool versionCheck(int clientFD);

    /* reads packet */
    bool readPacket(int pFD, SFPacket &pPacket);

    /* writes packet */
    bool writePacket(int pFD, SFPacket &pPacket);

    /* adds client to the list */
    void addClient(int clientFD);

    /* removes client from the list */
    void removeClient(int clientFD);

    /* checks for connecting clients - main thread for connection handling */
    void connectClients();

    /* checks for messages from the clients - producer thread */
    void readClients();

    /* write messages to clients (duplicate) - consumer thread */
    void writeClients();

    /* reports error to stderr */
    int reportError(const char *msg, int result);

    /* write something into pipe to wake up client readerThread */
    void stuffPipe();
    
    /* remove data written into pipe */
    void clearPipe();

public:
    /* create SF TCP server - init and start threads */
    TCPComm(int pPort, PacketBuffer &pReadBuffer, PacketBuffer &pWriteBuffer, sharedControlInfo_t& pControl);

    /* wait for threads, close fds and cleanup */
    ~TCPComm();

    /* cancels all running threads */
    void cancel();

    /* returns the TCP/IP port of this sf server */
    int getPort();

    /* reports status info to stdout */
    void reportStatus(std::ostream& os);

    /* returns if error occurred */
    bool isErrorReported() { return errorReported; }
};

#endif
