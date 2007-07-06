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

#include "sharedinfo.h"
#include "tcpcomm.h"
#include "sfpacket.h"
#include "stdio.h"

#include <iostream>
#include <set>

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <errno.h>
#include <fcntl.h>
#include <pthread.h>



using namespace std;

/* forward declarations of pthrad helper functions*/
void* checkClientsThread(void*);
void* readClientsThread(void*);
void* writeClientsThread(void*);

/* opens tcp server port for listening and start threads*/
TCPComm::TCPComm(int pPort, PacketBuffer &pReadBuffer, PacketBuffer &pWriteBuffer, sharedControlInfo_t& pControl) : readBuffer(pReadBuffer), writeBuffer(pWriteBuffer), errorReported(false), errorMsg(""), control(pControl)
{
    // init values
    writerThreadRunning = false;
    readerThreadRunning = false;
    serverThreadRunning = false;
    clientInfo.count = 0;
    clientInfo.FDs.clear();
    readPacketCount = 0;
    writtenPacketCount = 0;
    port = pPort;
    pthread_mutex_init(&clientInfo.sleeplock, NULL);
    pthread_mutex_init(&clientInfo.countlock, NULL);
    pthread_cond_init(&clientInfo.wakeup, NULL);

    struct sockaddr_in me;
    int opt;
    int rxBuf = 1024;
    
    serverFD = reportError("TCPComm::TCPComm : socket(AF_INET, SOCK_STREAM, 0)", socket(AF_INET, SOCK_STREAM, 0));
    memset(&me, 0, sizeof me);
    me.sin_family = AF_INET;
    me.sin_port = htons(port);

    opt = 1;
    if (!errorReported)
        reportError("TCPComm::TCPComm : setsockopt(serverFD, SOL_SOCKET, SO_REUSEADDR, (char *)&opt, sizeof(opt))", setsockopt(serverFD, SOL_SOCKET, SO_REUSEADDR, (char *)&opt, sizeof(opt)));
    if (!errorReported)
        reportError("TCPComm::TCPComm : setsockopt(serverFD, SOL_SOCKET, SO_RCVBUF, (char *)&rxBuf, sizeof(rxBuf))", setsockopt(serverFD, SOL_SOCKET, SO_RCVBUF, (char *)&rxBuf, sizeof(rxBuf)));
    if (!errorReported)
        reportError("TCPComm::TCPComm : bind(serverFD, (struct sockaddr *)&me, sizeof me)", bind(serverFD, (struct sockaddr *)&me, sizeof me));
    if (!errorReported)
        reportError("TCPComm::TCPComm : listen(serverFD, 5)", listen(serverFD, 5));

    // start thread for server socket (adding and removing clients)
    if (!errorReported)
    {
        if (reportError("TCPComm::TCPComm : pthread_create( &serverThread, NULL, checkClientsThread, this)", pthread_create( &serverThread, NULL, checkClientsThread, this)) == 0) 
            serverThreadRunning = true;
        // start thread for reading from client connections
        if (reportError("TCPComm::TCPComm : pthread_create( &readerThread, NULL, readClientsThread, this)", pthread_create( &readerThread, NULL, readClientsThread, this)) == 0)
            readerThreadRunning = true;
        // start thread for writing to client connections
        if (reportError("TCPComm::TCPComm : pthread_create( &writerThread, NULL, writeClientsThread, this)", pthread_create( &writerThread, NULL, writeClientsThread, this)) == 0)
            writerThreadRunning = true;
    }
}


TCPComm::~TCPComm()
{
    cancel();

    close(serverFD);
    set<int>::iterator it;
    for( it = clientInfo.FDs.begin(); it != clientInfo.FDs.end(); it++ )
    {
        close(*it);
    }
    pthread_mutex_destroy(&clientInfo.sleeplock);
    pthread_mutex_destroy(&clientInfo.countlock);
    pthread_cond_destroy(&clientInfo.wakeup);
}

int TCPComm::getPort()
{
    return port;
}

/* reads packet */
bool TCPComm::readPacket(int pFD, SFPacket &pPacket)
{
    char l;
    char* buffer[SFPacket::getMaxPayloadLength()];

    if (readFD(pFD, &l, 1) != 1)
    {
        return false;
    }
    if (l > SFPacket::getMaxPayloadLength())
    {
        return false;
    }
    if (readFD(pFD, (char*) buffer, static_cast<int>(l)) != l)
    {
        return false;
    }
    if (pPacket.setPayload((char*)buffer ,l))
    {
        return true;
    }
    else
    {
        return false;
    }
}

int TCPComm::writeFD(int fd, const char *buffer, int count)
{
    int actual = 0;
    while (count > 0)
    {
        int n = send(fd, buffer, count, MSG_NOSIGNAL);
        if (n == -1)
        {
            return -1;
        }
        count -= n;
        actual += n;
        buffer += n;
    }
    return actual;
}

/* writes packet */
bool TCPComm::writePacket(int pFD, SFPacket &pPacket)
{
    char len = pPacket.getLength();
    if (writeFD(pFD, &len, 1) != 1)
    {
        return false;
    }
    if (writeFD(pFD, pPacket.getPayload(), len) != len)
    {
        return false;
    }
    return true;
}

/* checks for correct version of SF protocol */
bool TCPComm::versionCheck(int clientFD)
{
    char check[2], us[2];
    int version;

    /* Indicate version and check if a TinyOS 2.0 serial forwarder on the other end */
    us[0] = 'U';
    us[1] = ' ';
    if (writeFD(clientFD, us, 2) != 2)
    {
        return false;
    }
    if (readFD(clientFD, check, 2) != 2)
    {
        return false;
    }
    if (check[0] != 'U')
    {
        return false;
    }

    version = check[1];
    if (us[1] < version)
    {
        version = us[1];
    }
    /* Add other cases here for later protocol versions */
    switch (version)
    {
    case ' ':
        break;
    default:
        return false;
    }

    return true;
}

/* adds a client to the client list and wakes up all threads */
void TCPComm::addClient(int clientFD)
{
    DEBUG("TCPComm::addClient : lock")
    pthread_testcancel();
    pthread_mutex_lock( &clientInfo.countlock );
    bool wakeupClientThreads = false;
    if (clientInfo.count == 0)
    {
        wakeupClientThreads = true;
    }
    ++clientInfo.count;
    clientInfo.FDs.insert(clientFD);
    if (wakeupClientThreads)
    {
        pthread_cond_broadcast( &clientInfo.wakeup );
    }
    pthread_mutex_unlock( &clientInfo.countlock );
    DEBUG("TCPComm::addClient : unlock")
}

void TCPComm::removeClient(int clientFD)
{
    DEBUG("TCPComm::removeClient : lock")
    pthread_testcancel();
    pthread_mutex_lock( &clientInfo.countlock );
    if (clientInfo.count > 0)
    {
        clientInfo.FDs.erase(clientFD);
        if (close(clientFD) != 0)
        {
            DEBUG("TCPComm::removeClient : error closing fd " << clientFD)
        }
        else
        {
            --clientInfo.count;
        }
    }
    if (clientInfo.count == 0)
    {
        // clear write buffer
        writeBuffer.clear();
    }
    pthread_mutex_unlock( &clientInfo.countlock );
    DEBUG("TCPComm::removeClient : unlock")
}

/* helper function to start server pthread */
void* checkClientsThread(void* ob)
{
    static_cast<TCPComm*>(ob)->connectClients();
    return NULL;
}

/* checks for new connected clients */
void TCPComm::connectClients()
{
    while (true)
    {
        int clientFD = accept(serverFD, NULL, NULL);
	pthread_testcancel();
        if (clientFD >= 0)
        {
            if (versionCheck(clientFD))
            {
                addClient(clientFD);
            }
            else
            {
                close(clientFD);
            }
        }
        else
        {
            pthread_testcancel();
            cancel();
        }
    }
}

/* helper function to start client reader pthread */
void* readClientsThread(void* ob)
{
    static_cast<TCPComm*>(ob)->readClients();
    return NULL;
}

/* reads from connected clients */
void TCPComm::readClients()
{
    FD_t clientFDs;
    while (true)
    {
        pthread_cleanup_push((void(*)(void*)) pthread_mutex_unlock, (void *) &clientInfo.countlock);
        pthread_mutex_lock( &clientInfo.countlock );
        while( clientInfo.count == 0 )
        {
            // do nothing when no client is connected...
            DEBUG("TCPComm::readClients : sleeping reader thread")
            pthread_cond_wait( &clientInfo.wakeup, &clientInfo.countlock );
        }
        // copy set in to temp set
        clientFDs = clientInfo.FDs;
        // removes the cleanup handler and executes it (unlock mutex)
        pthread_cleanup_pop(1); 

        // check all fds (work with temp set)...
        fd_set rfds;
        FD_ZERO(&rfds);
        int maxFD = -1;
        set<int>::iterator it;
        for( it = clientFDs.begin(); it != clientFDs.end(); it++ )
        {
            if (*it > maxFD)
            {
                maxFD = *it;
            }
            FD_SET(*it, &rfds);
        }
        if (select(maxFD + 1, &rfds, NULL, NULL, NULL) < 0 )
        {
            //             run = false;
            reportError("TCPComm::readClients : select(maxFD+1, &rfds, NULL, NULL NULL)", -1);
        }
        else
        {
            for ( it = clientFDs.begin(); it != clientFDs.end(); it++)
            {
                if (FD_ISSET(*it, &rfds))
                {
                    SFPacket packet;
                    if (readPacket(*it, packet))
                    {
                        // this call blocks until buffer is not full
                        readBuffer.enqueueBack(packet);
                        ++readPacketCount;
                    }
                    else
                    {
                        DEBUG("TCPComm::readClients : removeClient")
                        removeClient(*it);
                    }
                }
            }
        }
    }
}

/* helper function to start client writer pthread */
void* writeClientsThread(void* ob)
{
    static_cast<TCPComm*>(ob)->writeClients();
    return NULL;
}

/* writes to connected clients */
void TCPComm::writeClients()
{
    FD_t clientFDs;
    while (true)
    {
        pthread_cleanup_push((void(*)(void*)) pthread_mutex_unlock, (void *) &clientInfo.countlock);
        pthread_mutex_lock( &clientInfo.countlock );
        while( clientInfo.count == 0 )
        {
            // do nothing when no client is connected...
            DEBUG("TCPComm::writeClients : sleeping writer thread")
            pthread_cond_wait( &clientInfo.wakeup, &clientInfo.countlock );
        }
        // removes the cleanup handler and executes it (unlock mutex)
        pthread_cleanup_pop(1); 

        // blocks until buffer is not empty
        SFPacket packet = writeBuffer.dequeue();
        pthread_testcancel();
        pthread_mutex_lock( &clientInfo.countlock );
        // copy client fd set into temp set
        clientFDs = clientInfo.FDs;
        pthread_mutex_unlock( &clientInfo.countlock );

        // check all fds (work with temp set)...
        set<int>::iterator it;
        // duplicate and send out packet to all connected clients
        for( it = clientFDs.begin(); it != clientFDs.end(); it++ )
        {
            if (writePacket(*it, packet))
            {
                ++writtenPacketCount;
            }
            else
            {
                DEBUG("TCPComm::writeClients : removeClient")
                removeClient(*it);
            }
        }
    }
}

/* cancels all running threads */
void TCPComm::cancel()
{
    pthread_t callingThread = pthread_self();
    if (pthread_equal(callingThread, readerThread))
    {
        DEBUG("TCPComm::cancel : by readerThread")
        pthread_detach(readerThread);
        if (writerThreadRunning)
        {
            pthread_cancel(writerThread);
            DEBUG("TCPComm::cancel : writerThread canceled, joining")
            pthread_join(writerThread, NULL);
            writerThreadRunning = false;
        }
        if (serverThreadRunning)
        {
            pthread_cancel(serverThread);
            DEBUG("TCPComm::cancel : serverThread canceled, joining")
            pthread_join(serverThread, NULL);
            serverThreadRunning = false;
        }
        readerThreadRunning = false;
	pthread_cond_signal(&control.cancel);
        pthread_exit(NULL);
    }
    else if (pthread_equal(callingThread, writerThread))
    {
        DEBUG("TCPComm::cancel : by writerThread")
        pthread_detach(writerThread);
        if (readerThreadRunning)
        {
            pthread_cancel(readerThread);
            DEBUG("TCPComm::cancel : readerThread canceled, joining")
            pthread_join(readerThread, NULL);
            readerThreadRunning = false;
        }
        if (serverThreadRunning)
        {
            pthread_cancel(serverThread);
            DEBUG("TCPComm::cancel : serverThread canceled, joining")
            pthread_join(serverThread, NULL);
            serverThreadRunning = false;
        }
        writerThreadRunning = false;
	pthread_cond_signal(&control.cancel);
        pthread_exit(NULL);
    }
    else if (pthread_equal(callingThread, serverThread))
    {
        DEBUG("TCPComm::cancel : by serverThread")
        pthread_detach(serverThread);
        if (readerThreadRunning)
        {
            pthread_cancel(readerThread);
            DEBUG("TCPComm::cancel : readerThread canceled, joining")
	    pthread_join(readerThread, NULL);
            readerThreadRunning = false;
        }
        if (writerThreadRunning)
        {
            pthread_cancel(writerThread);
            DEBUG("TCPComm::cancel : writerThread canceled, joining")
            pthread_join(writerThread, NULL);
            writerThreadRunning = false;
        }
        serverThreadRunning = false;
	pthread_cond_signal(&control.cancel);
        pthread_exit(NULL);
    }
    else
    {
        DEBUG("TCPComm::cancel : by other thread")
	if (serverThreadRunning)
        {
            pthread_cancel(serverThread);
            DEBUG("TCPComm::cancel : serverThread canceled, joining")
            pthread_join(serverThread, NULL);
            serverThreadRunning = false;
        }
 	if (writerThreadRunning)
        {
            pthread_cancel(writerThread);
            DEBUG("TCPComm::cancel : writerThread canceled, joining")
            pthread_join(writerThread, NULL);
            writerThreadRunning = false;
        }
        if (readerThreadRunning)
        {
            pthread_cancel(readerThread);
            DEBUG("TCPComm::cancel : readerThread canceled, joining")
            pthread_join(readerThread, NULL);
            readerThreadRunning = false;
        }
	pthread_cond_signal(&control.cancel);
    }
}

/* reports error */
int TCPComm::reportError(const char *msg, int result)
{
    if ((result < 0) && (!errorReported))
    {
        errorMsg << "error : SF-Server (TCPComm on port = " << port << ") : "
        << msg << " ( result = " << result << " )" << endl
        << "error-description : " << strerror(errno) << endl;

        cerr << errorMsg.str();
        errorReported = true;
        cancel();
    }
    return result;
}

/* prints out status */
void TCPComm::reportStatus(ostream& os)
{
    os << "SF-Server ( TCPComm on port " << port << " )"
    << " : clients = " << clientInfo.count
    << " , packets read = " << readPacketCount
    << " , packets written = " << writtenPacketCount << endl;
}
