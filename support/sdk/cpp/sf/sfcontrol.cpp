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

#include "sfcontrol.h"
#include "sharedinfo.h"

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <errno.h>
#include <fcntl.h>

#include <string>
#include <iostream>
#include <sstream>
#include <fstream>
#include <list>


using namespace std;

/* forward declarations of pthrad helper functions*/
void* checkCancelThread(void*);

SFControl::SFControl()
{
    servers.clear();
    pthread_mutex_init(&sfControlInfo.lock, NULL);
    pthread_cond_init(&sfControlInfo.cancel, NULL);

    FD_ZERO(&rfds);
    FD_ZERO(&wfds);
    uniqueId = 0;
    servers.clear();
    serverFD = -1;
    clientFD = -1;
    controlPort = -1;
    controlServerStarted = false;
    daemon = false;
    reportError("SFControl::SFControl : pthread_create( &cancelThread, NULL, checkCancelThread, this)", pthread_create( &cancelThread, NULL, checkCancelThread, this));
}


SFControl::~SFControl()
{
    close(serverFD);
    pthread_mutex_destroy(&sfControlInfo.lock);
    pthread_cond_destroy(&sfControlInfo.cancel);
}

string SFControl::getHelpMessage(string msg)
{
    stringstream helpMessage;
    if (msg == "help arguments")
    {
        // genral help message for command line arguments
        helpMessage << "sf - Controls (starting/stopping) several SFs on one machine" << endl << endl
        << "Usage : sf" << endl
        << "or    : sf control-port PORT_NUMBER daemon" << endl << endl
        << "Arguments:" << endl
        << "        control-port PORT_NUMBER : TCP port on which commands are accepted" << endl 
        << "        daemon : this switch (if present) makes sf aware that it may be running as a daemon " << endl << endl
        << "Info:" << endl
        << "        If sf is started without arguments it listen on " << endl
        << "        standard input for commands (for a list type \"help\" when sf is running)." << endl
        << "        If it is started with a given control-port (e.g.: sf control-port 9009)" << endl
        << "        sf listen on the given TCP control port _and_ the standard" << endl
        << "        input." << endl;

    }
    else if (msg == "start")
    {
        helpMessage << ">> start PORT DEVICE_NAME BAUDRATE:" << endl
        << ">> Starts a sf-server on a given TCP port connecting to a given device with the given baudrate." << endl
        << ">> The TCP port device name must be specified and must not" << endl
        << ">> overlap with any other TCP port or device name pair of an already running sf-server." << endl
        << ">> (e.g: \"start 9002 /dev/ttyUSB2 115200\" starts server on port 9002 and device /dev/ttyUSB2 with baudrate 115200)" << endl;
    }
    else if (msg == "stop")
    {
        helpMessage << ">> stop ID | PORT | DEVICE_NAME:" << endl
        << ">> Stops the specified sf-server." << endl
        << ">> The unique id or the device or the TCP port of the" << endl
        << ">> sf-server must be specified." << endl
        << ">> (e.g: \"stop 1\" stops server with id 1 " << endl
        << ">>      \"stop /dev/ttyUSB0\" stops server connected to /dev/ttyUSB0" << endl
        << ">>      \"stop 9002\" prints stops server listening on TCPport 90002)" << endl;
    }
    else if (msg == "info")
    {
        helpMessage << ">> info ID | PORT | DEVICE_NAME:" << endl
        << ">> Prints some information about a given sf-server." << endl
        << ">> The unique id or the device or the TCP port of the" << endl
        << ">> sf-server must be specified." << endl
        << ">> (e.g: \"info 1\" prints out information about server with id 1 " << endl
        << ">>      \"info /dev/ttyUSB0\" prints out information about server connected to /dev/ttyUSB0" << endl
        << ">>      \"info 9002\" prints out information about server listening on TCPport 90002)" << endl;
    }
    else if (msg == "list")
    {
        helpMessage << ">> list:" << endl
        << ">> Displays a list of currently running sf-servers." << endl
        << ">> A List Entry contains the unique id, the TCP port and the device" << endl
        << ">> of a sf-server." << endl;
    }
    else if (msg == "close")
    {
        helpMessage << ">> close:" << endl
        << ">> Closes the TCP connection to the control client." << endl
        << ">> It can be issued only if the control-server is started."<< endl;
    }
    else if (msg == "exit")
    {
        helpMessage << ">> exit:" << endl
        << ">> Immediatly exits and kills all running sf-servers." << endl
        << ">> This ends everything gracefully..." << endl;
    }
    else
    {
        // genral help message for interactive commands
        helpMessage << ">> Supported commands are:" << endl
        << ">> " << endl
        << ">> start - starts a sf-server on a given port and device" << endl
        << ">> stop  - stops a running sf-server" << endl
        << ">> list  - lists all running sf-servers" << endl
        << ">> info  - prints out some information about a given sf-server" << endl;
        if (controlServerStarted) {
          helpMessage << ">> close - closes the TCP connection to the control-client" << endl;
        }
        helpMessage << ">> exit  - immediatly exits and kills all running sf-servers" << endl
        << ">>" << endl
        << ">> By typing \"help\" followd by a command (e.g.: \"help start\")" << endl
        << ">> detailed information about that command is printed." << endl;


    }
    return helpMessage.str();
}


void SFControl::parseArgs(int argc, char *argv[])
{
    if (argc == 1)
    {
        os << ">> Starting sf-control." << endl;
        os << ">> Accepting commands on standard input..." << endl;
        deliverOutput();
        // test standard port before
    }
    else if (argc >= 3)
    {
        int port = -1;
        string argPort(argv[2]);
        stringstream helpStream(argPort);
        helpStream >> port;
        if ((strncmp(argv[1], "control-port", 13) >= 0) && (port > 0))
        {
            controlPort = port;
            startControlServer();
            os << ">> Accepting commands on TCP port " << controlPort ;
	    if(argc == 3) {
	      os << " and on standard input..." << endl;
	      daemon = false;
	    }
	    else {
	      os << " but not on standard input..." << endl;
	      daemon = true;
	    }
            deliverOutput();
        }
        else
        {
            os << getHelpMessage("help arguments");
            deliverOutput();
            exit(1);
        }
    }
    else
    {
        os << getHelpMessage("help arguments");
        deliverOutput();
        exit(1);
    }
}

/* starts a sf-server */
void SFControl::startServer(int port, string device, int baudrate)
{
    pthread_testcancel();
    pthread_mutex_lock(&sfControlInfo.lock);
    sfServer_t newSFServer;
    newSFServer.serial2tcp = new PacketBuffer();
    newSFServer.tcp2serial = new PacketBuffer();
    newSFServer.TcpServer = new TCPComm(port, *(newSFServer.tcp2serial), *(newSFServer.serial2tcp), sfControlInfo);
    newSFServer.SerialDevice = new SerialComm(device.c_str(), baudrate, *(newSFServer.serial2tcp), *(newSFServer.tcp2serial), sfControlInfo);
    newSFServer.id = ++uniqueId;
    servers.push_back(newSFServer);
    pthread_mutex_unlock(&sfControlInfo.lock);
}

/* stops a given sf-server. returns false if specified server not running */
bool SFControl::stopServer(int& id, int& port, string& device)
{
    pthread_testcancel();
    pthread_mutex_lock(&sfControlInfo.lock);
    bool found = false;
    list<sfServer_t>::iterator it = servers.begin();
    list<sfServer_t>::iterator next = it;
    while( (it != servers.end()) && (!found))
    {
        ++next;
        if (((*it).SerialDevice->getDevice() == device) || ((*it).TcpServer->getPort() == port) || ((*it).id == id) )
        {
            // cancel
            (*it).TcpServer->cancel();
            (*it).SerialDevice->cancel();
            // set id, port and device accordingly
            id = (*it).id;
            port = (*it).TcpServer->getPort();
            device = (*it).SerialDevice->getDevice();
            // clean up
            delete (*it).TcpServer;
            delete (*it).SerialDevice;
            delete (*it).tcp2serial;
            delete (*it).serial2tcp;
            servers.erase(it);
            found = true;
        }
        it = next;
    }
    pthread_mutex_unlock(&sfControlInfo.lock);
    return found;
}

/* prints out server info for specified server */
bool SFControl::showServerInfo(ostream& pOs, int id, int port, string device)
{
    pthread_testcancel();
    pthread_mutex_lock(&sfControlInfo.lock);
    bool found = false;
    list<sfServer_t>::iterator it = servers.begin();
    list<sfServer_t>::iterator next = it;
    while( it != servers.end() && (!found))
    {
        ++next;
        if (((*it).SerialDevice->getDevice() == device) || ((*it).TcpServer->getPort() == port) || ((*it).id == id) )
        {
            pOs << ">> info for sf-server with id = " << (*it).id
            << " ( port =  " << (*it).TcpServer->getPort()
            << " , device = " << (*it).SerialDevice->getDevice()
            << " , baudrate = " << (*it).SerialDevice->getBaudRate()
            << " )" << endl;
            pOs << ">> ";
            (*it).TcpServer->reportStatus(os);
            pOs << ">> ";
            (*it).SerialDevice->reportStatus(os);
            found = true;
        }
        it = next;
    }
    pthread_mutex_unlock(&sfControlInfo.lock);
    return found;
}

/* lists all running servers */
void SFControl::listServers(ostream& pOs)
{
    pthread_testcancel();
    pthread_mutex_lock(&sfControlInfo.lock);
    list<sfServer_t>::iterator it = servers.begin();
    for ( it = servers.begin(); it != servers.end(); it++ )
    {
        pOs << ">> sf-server id = " << (*it).id
        << " , port = " << (*it).TcpServer->getPort()
        << " , device = " << (*it).SerialDevice->getDevice()
        << " , baudrate = " << (*it).SerialDevice->getBaudRate() << endl;
    }
    if (servers.size() == 0)
    {
        pOs << ">> none" << endl;
    }
    pthread_mutex_unlock(&sfControlInfo.lock);
}

void SFControl::parseInput(std::string arg)
{
    /* silly, but works ... */
    string strBuf;
    stringstream parseStream(arg);
    vector<string> tokens;
    while (parseStream >> strBuf)
        tokens.push_back(strBuf);

    if (tokens[0] == "start")
    {
        if (tokens.size() == 4)
        {
            if (servers.size() < maxSFServers)
            {
                os << ">> Trying to start sf-server with id = " << (uniqueId+1)
                << " ( port = " << tokens[1]
                << " , device = " << tokens[2]
                << " , baudrate = " << tokens[3]
                << " )" << endl;
                deliverOutput();
                stringstream helpInt;
                int baudrate = 0;
                int port = 0;
                helpInt << tokens[3] << " " << tokens[1];
                helpInt >> baudrate >> port;
                startServer(port, tokens[2], baudrate);
            }
            else
            {
                os << ">> FAIL: Too many running servers (currently " << servers.size() << " servers running)" << endl;
                deliverOutput();
            }
        }
        else
        {
            os << getHelpMessage("start");
            deliverOutput();
        }
    }
    else if (tokens[0] == "stop")
    {
        if (tokens.size() == 2)
        {
            stringstream helpInt;
            int port = 0;
            int id = -1;
            helpInt << tokens[1] << " " << tokens[1];
            helpInt >> id >> port;
            if (!stopServer(id, port, tokens[1]))
            {
                os << ">> no sf-server with id / device / baudrate = " << tokens[1] << " found!" << endl;
                deliverOutput();
            }
            else
            {
                os << ">> stopped sf-server with id = " << id
                << " ( port =  " << port
                << " , device = " << tokens[1]
                << " )" << endl;
                deliverOutput();
            }
        }
        else
        {
            os << getHelpMessage("stop");
            deliverOutput();
        }
    }
    else if (tokens[0] == "info")
    {
        if (tokens.size() == 2)
        {

            stringstream helpInt;
            int port = 0;
            int id = -1;
            helpInt << tokens[1] << " " << tokens[1];
            helpInt >> id >> port;
            if (!showServerInfo(os, id, port, tokens[1]))
            {
                os << ">> no sf-server with id / device / baudrate = " << tokens[1] << " found!" << endl;
                deliverOutput();
            } else {
                deliverOutput();
	    }
        }
        else
        {
            os << getHelpMessage("info");
            deliverOutput();
        }
    }
    else if ((tokens[0] == "close") && (controlServerStarted))
    {
        if (clientFD > 0) {
        	os << ">> closing connection to control-client " << endl;
       		deliverOutput();
        	close(clientFD);
        	clientFD = -1;
        }
    }
    else if (tokens[0] == "list")
    {
        os << ">> currently running sf-servers:" << endl;
        listServers(os);
        deliverOutput();
    }
    else if (tokens[0] == "exit")
    {
        os << ">> exiting..." << endl;
        deliverOutput();
        exit(0);
    }
    else
    {
        if ((tokens[0] == "help") && (tokens.size() == 2))
        {
            os << getHelpMessage(tokens[1]);
            deliverOutput();
        }
        else
        {
            os << getHelpMessage(tokens[0]);
            deliverOutput();
        }

    }
}

/* send string to connected client.. */
bool SFControl::sendToClient(string message)
{
    if (clientFD < 0)
        return false;
    int length = message.size();
    const char* buffer = message.c_str();
    while (length > 0)
    {
#ifdef __APPLE__
        int n = send(clientFD, buffer, length, 0);
#else
        int n = send(clientFD, buffer, length, MSG_NOSIGNAL);
#endif
        if (!(n > 0))
        {
            return false;
        }
        length -= n;
        buffer += n;
    }
    return true;
}

/* receive string from connected client... */
bool SFControl::readFromClient(string& message)
{
    if (clientFD < 0)
        return false;
    int length = 0;
    char buffer[256];
    char* bufPtr = buffer;
    *bufPtr = '\0';
    do
    {
        int n = read(clientFD, (void *) bufPtr, 1);
        if (!(n > 0))
        {
            return false;
        }
    }
    while ((*bufPtr++ != '\n') && (length++ < 255));
    buffer[length] = '\0';
    message = (length == 1) ? "" : buffer;
    return true;
}

void SFControl::waitOnInput()
{
    bool clientConnected = false;

    struct sockaddr_in client;
    unsigned int clientAddrLen = sizeof(client);
    FD_ZERO(&rfds);

    while (true)
    {
        int maxfd = 0;
	if(daemon) {
	  FD_CLR(0, &rfds);
	}
	else {
	  FD_SET(0, &rfds);
	}
        if (controlServerStarted)
        {
            FD_SET(serverFD, &rfds);
            maxfd = (serverFD > maxfd) ? serverFD : maxfd;
        }
        if (clientConnected)
        {
            FD_SET(clientFD, &rfds);
            maxfd = (clientFD > maxfd) ? clientFD : maxfd;
        }

        reportError("SFControl::waitOnInput : select(maxfd+1, &rfds, NULL, NULL, NULL)", select(maxfd+1, &rfds, NULL, NULL, NULL));

        if (FD_ISSET(0, &rfds))
        {
            /* parse standard input */
            FD_CLR(0, &rfds);
            string input = "";
            getline (cin, input);
            if (input != "")
            {
                os << "standard input : " << input << endl;
                if (!(clientFD < 0))
                    sendToClient(os.str());
                os.str("");
                os.clear();
                parseInput(input);
            }
        }
        if (clientFD == -1) clientConnected = false;
        if (controlServerStarted)
        {
            if (FD_ISSET(serverFD, &rfds))
            {
                /* we got a new connection request */
                FD_CLR(serverFD, &rfds);
                int newClientFD = reportError("SFControl::waitOnInput : accept(serverFD, (struct sockaddr*) &client, &clientAddrLen)", accept(serverFD, (struct sockaddr*) &client, &clientAddrLen));
                if ((newClientFD >= 0) && (!clientConnected))
                {
                    clientFD = newClientFD;
                    clientConnected = true;
                    os << ">> accepted connection from control-client " << inet_ntoa(client.sin_addr) << endl;
                    deliverOutput();
                }
                else
                {
                    close(newClientFD);
                }
            }
        }
        if (clientConnected)
        {
            if (FD_ISSET(clientFD, &rfds))
            {
                /* we got data from the connected control client */
                FD_CLR(clientFD, &rfds);
                string input = "";
                if (readFromClient(input))
                {
                    if (input != "")
                    {
                        os << "control-client : " << input << endl;
                        cout << os.str();
                        os.str("");
                        os.clear();
                        parseInput(input);
                    }
                }
                else
                {
                    os << ">> closing connection to control-client " << inet_ntoa(client.sin_addr) << endl;
                    deliverOutput();
                    close(clientFD);
                    clientFD = -1;
                }
            }
        }
        if (clientFD == -1) clientConnected = false;
    }
}

void* checkCancelThread(void* ob)
{
    static_cast<SFControl*>(ob)->checkThreadCancel();
    return NULL;
}

/* keeps track of self-canceled sf-servers */
void SFControl::checkThreadCancel()
{
    while(true)
    {
        pthread_testcancel();
        pthread_mutex_lock(&sfControlInfo.lock);
        pthread_cond_wait(&sfControlInfo.cancel, &sfControlInfo.lock);
        list<sfServer_t>::iterator it = servers.begin();
        list<sfServer_t>::iterator next = it;

        while( it != servers.end() )
        {
            ++next;
            if ((*it).TcpServer->isErrorReported() || (*it).SerialDevice->isErrorReported())
            {
                // cancel
                (*it).TcpServer->cancel();
                (*it).SerialDevice->cancel();
                // inform user
                os << ">> FAIL: sf-server with id = " << (*it).id
                << " ( port =  " << (*it).TcpServer->getPort()
                << " , device = " << (*it).SerialDevice->getDevice()
                << " ) canceled" << endl;
                deliverOutput();
                // clean up
                delete (*it).TcpServer;
                delete (*it).SerialDevice;
                delete (*it).tcp2serial;
                delete (*it).serial2tcp;
                servers.erase(it);
            }
            it = next;
        }
        pthread_mutex_unlock(&sfControlInfo.lock);
    }
}


void SFControl::startControlServer()
{
    struct sockaddr_in me;
    int opt = 1;

    serverFD = reportError("SFControl::startControlServer : socket(AF_INET, SOCK_STREAM, 0)", socket(AF_INET, SOCK_STREAM, 0));
    reportError("SFControl::startControlServer : fcntl(serverFD, F_SETFL, O_NONBLOCK)", fcntl(serverFD, F_SETFL, O_NONBLOCK));

    memset(&me, 0, sizeof me);
    me.sin_family = AF_INET;
    me.sin_port = htons(controlPort);

    reportError("SFControl::startControlServer : setsockopt(serverFD, SOL_SOCKET, SO_REUSEADDR, (char *)&opt, sizeof(opt))", setsockopt(serverFD, SOL_SOCKET, SO_REUSEADDR, (char *)&opt, sizeof(opt)));
    reportError("SFControl::startControlServer : bind(serverFD, (struct sockaddr *)&me, sizeof me)", bind(serverFD, (struct sockaddr *)&me, sizeof me));
    reportError("SFControl::startControlServer : listen(serverFD, 1)", listen(serverFD, 1));
    controlServerStarted = true;
}

void SFControl::deliverOutput()
{
    if (!(clientFD < 0))
        sendToClient(os.str());
    cout << os.str();
    os.str("");
    os.clear();
}

/* reports error */
int SFControl::reportError(const char *msg, int result)
{
    if (result < 0)
    {
        cerr << "FATAL : SF-Control-Server : "
        << msg << " ( result = " << result << " )" << endl
        << "error-description : " << strerror(errno) << endl;
        exit(1);
    }
    return result;
}

