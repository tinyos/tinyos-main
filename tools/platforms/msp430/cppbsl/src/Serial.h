/* -*- mode:c++; indent-tabs-mode:nil -*-
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
 * hand rolled bsl tool, other ones are too slow
 * @author Andreas Koepke <koepke at tkn.tu-berlin.de>
 * @date 2007-04-16
 */
#ifndef BSL_SERIAL_H
#define BSL_SERIAL_H

#include <string>
#include <inttypes.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <sys/time.h>
#include <sys/types.h>
#include <termios.h>
#include <unistd.h>
#include <iostream>
#include <errno.h>
#include <linux/serial.h>
#include "Parameters.h"

inline void serial_delay(unsigned usec) {
    struct timeval tv;
    tv.tv_sec = usec/1000000;
    tv.tv_usec = usec%1000000;
    select(0,NULL,NULL,NULL, &tv);
};

struct frame_t {
    uint8_t HDR;
    uint8_t CMD;
    uint8_t L1;
    uint8_t L2;
    uint8_t AL;
    uint8_t AH;
    uint8_t LL;
    uint8_t LH;
    uint8_t data[252];
} __attribute__ ((packed));

/**
 * Connect with serial device (dev), returns the opened file descriptors in *
 * readFD and writeFD. Returns on error with something != 0 and errno is *
 * hopefully set correctly.
*/
int serial_connect(int* err, const char* dev, int* readFD, int* writeFD, termios* pt);

class BaseSerial {
protected:
    const int switchdelay;
    termios oldtermios;
    
protected:
    int serialReadFD;
    int serialWriteFD;
    bool invertTest;
    bool invertReset;
    bool swapRstTest;
    
    fd_set rfds;
    
    enum {
	CMD_FAILED = 0x70,
	SYNC = 0x80,
	DATA_ACK = 0x90,
	DATA_NAK = 0xA0,
    };
    
 protected:    
    inline int setDTR(int *err) {
        int i = TIOCM_DTR;
        int r = ioctl(serialWriteFD, TIOCMBIS, &i);
        if(r == -1) {
            *err = errno;
            std::cerr << "ERROR: BaseSerial::setDTR could not set DTR pin" << std::endl;
        }
        else {
            serial_delay(switchdelay);
        }
        return r;
    }
    inline int clrDTR(int *err) {
        int i = TIOCM_DTR;
        int r = ioctl(serialWriteFD, TIOCMBIC, &i);
        if(r == -1) {
            *err = errno;
            std::cerr << "ERROR: BaseSerial::clrDTR could not clr DTR pin" << std::endl;
        }
        else {
            serial_delay(switchdelay);
        }
        return r;
    }
    inline int setRTS(int *err) {
        int i = TIOCM_RTS;
        int r = ioctl(serialWriteFD, TIOCMBIS, &i);
        if(r == -1) {
            *err = errno;
            std::cerr << "ERROR: BaseSerial::setRTS could not set RTS pin" << std::endl;
        }
        else {
            serial_delay(switchdelay);
        }
        return r;
    }
    inline int clrRTS(int *err) {
        int i = TIOCM_RTS;
        int r = ioctl(serialWriteFD, TIOCMBIC, &i);
        if(r == -1) {
            *err = errno;
            std::cerr << "ERROR: BaseSerial::clrRTS could not clr RTS pin" << std::endl;
        }
        else {
            serial_delay(switchdelay);
        }
        return r;
    }
    
    int setTEST(int *err) {
        int r;
        if(invertTest) { r = clrRTS(err); } else { r = setRTS(err); }
        return r;
    }

    int clrTEST(int *err) {
        int r;
        if(invertTest) { r = setRTS(err); } else { r = clrRTS(err); }
        return r;
    }

    int setRST(int *err) {
        int r;
        if(invertReset) { r = clrDTR(err); } else { r = setDTR(err); }
        return r;
    }

    int clrRST(int *err) {
        int r;
        if(invertReset) { r= setDTR(err); } else { r = clrDTR(err); }
        return r;
    }

    inline void checksum(frame_t *frame) {
        uint8_t i;
        uint8_t frameLen = frame->L1/2 + 2;
        uint16_t *dat = (uint16_t *)frame;
        uint16_t check = 0;
        for(i = 0; i < frameLen; i++) {
            check ^= dat[i];
        }
        dat[i] = ~check;
    }
    
    int readFD(int *err, char *buffer, int count, int maxCount);
    virtual int resetPins(int *err);
    
public:
    BaseSerial(const termios& term, int rFD, int wFD, bool T=false, bool R=false) :
        switchdelay(10),
        oldtermios(term),
        serialReadFD(rFD), serialWriteFD(wFD),
        invertTest(T), invertReset(R) {
        int err;
        FD_ZERO(&rfds);
        setRST(&err);
        setTEST(&err);
    }
    
    virtual ~BaseSerial() {
        int r;
        int err;
        if((serialReadFD != -1) || (serialWriteFD != -1))  {
            r = disconnect(&err);
        }
    }
    
    // communicate
    inline int clearBuffers(int *err) {
        int r = tcflush(serialReadFD, TCIOFLUSH);
        if(r != 0) {
            *err = errno;
        }
        else {
            r = tcflush(serialWriteFD, TCIOFLUSH);
            if(r != 0) {
                *err = errno;
            }
        }
        return r;
    };
    
    int txrx(int *err, frame_t *txframe, frame_t *rxframe);
    
    // handle connection
    int disconnect(int *err);

    // change connection speed
    int highSpeed(int *err);

    // do initial magic on serial interface
    virtual int reset(int *err);
    virtual int invokeBsl(int *err);

};

class TelosBSerial : public BaseSerial {    
protected:
    virtual int resetPins(int *err);
        
    int telosSetSCL(int *err) {
        return clrRTS(err);
    }
    
    int telosClrSCL(int *err) {
        return setRTS(err);
    }
    
    int telosSetSDA(int *err) {
        return clrDTR(err);
    }

    int telosClrSDA(int *err) {
        return setDTR(err);
    }

    int telosI2CStart(int *err);
    int telosI2CStop(int *err);
    int telosI2CWriteBit(int *err, bool bit);
    int telosI2CWriteByte(int* err, uint8_t byte);
    int telosI2CWriteCmd(int*err, uint8_t addr, uint8_t cmdbyte);
    
public:    
    TelosBSerial(const termios& term, int rFD, int wFD, bool T=false, bool R=false) :
        BaseSerial(term, rFD, wFD, T, R) {
    }
    
    virtual ~TelosBSerial() {
    }
    
    virtual int reset(int *err);
    virtual int invokeBsl(int *err);    


};

#endif
