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

#ifndef SFCONTROL_H
#define SFCONTROL_H

#include "stdio.h"
#include "packetbuffer.h"
#include "tcpcomm.h"
#include "serialcomm.h"
#include "pthread.h"
#include <vector>
#include <string>

class SFControl
{
protected:

    typedef struct
    {
        PacketBuffer* serial2tcp;
        PacketBuffer* tcp2serial;
        TCPComm* TcpServer;
        SerialComm* SerialDevice;
        int id;
    }
    sfServer_t;

    /* needed to get informed about canceled threads */
    sharedControlInfo_t sfControlInfo;

    /* list of running / started sf-servers */
    std::list<sfServer_t> servers;

    /* max. allowed sf-servers */
    static const unsigned int maxSFServers = 4;

    /* pthread for thread cancel notification */
    pthread_t cancelThread;

    /* read fd set */
    fd_set rfds;

    /* write fd set */
    fd_set wfds;

    /* indicated that the control server is started */
    bool controlServerStarted;

    /* in daemon mode: do not read from stdin */
    bool daemon;

    /* tcp port the control server listens on */
    int controlPort;

    /* control server FD */
    int serverFD;

    /* control-client fd */
    int clientFD;

    /* string stream for multiplexing output (cout and control-client) */
    std::ostringstream os;

    friend void* checkCancelThread(void* ob);

    /* needed for id generation */
    int uniqueId;

public:

    SFControl();

    ~SFControl();

    /* gets corresponding help message to command */
    std::string getHelpMessage(std::string msg = "");

    /* parses command line arguments */
    void parseArgs(int argc, char *argv[]);

    /* parses input */
    void parseInput(std::string arg);

    /* main loop, waits for input */
    void waitOnInput();

protected:
    /* checks if child threads canceled themselves */
    void checkThreadCancel();

    /* starts the controling server */
    void startControlServer();

    /* send string to connected client.. */
    bool sendToClient(std::string message);

    /* receive string from connected client... */
    bool readFromClient(std::string& message);

    /* starts a sf-server */
    void startServer(int port, std::string device, int baudrate);

    /* stops a given sf-server. returns false if specified server not running */
    bool stopServer(int& id, int& port, std::string& device);

    /* prints out server info for specified server */
    bool showServerInfo(std::ostream& pOs, int id, int port, std::string device);

    /* lists all running servers */
    void listServers(std::ostream& pOs);

    /* send output to console and/or to connected control client */
    void deliverOutput();

    /* reports error to stderr */
    int reportError(const char *msg, int result);
};



#endif
