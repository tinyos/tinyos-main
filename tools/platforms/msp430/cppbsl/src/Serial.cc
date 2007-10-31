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
#include <stdio.h>
#include <iostream>

#include "Serial.h"

using namespace std;

int serial_connect(int* err, const char* dev, int* readFD, int* writeFD, termios* pt)
{
    struct termios my_tios;
    struct serial_struct serinfo;
    int r = 0;
    *readFD = -1;
    *writeFD = -1;
    for(int i = 0; i < 3; i++) {
        *readFD = open(dev, O_RDONLY | O_NOCTTY | O_NONBLOCK);
        *err = errno;
        if(*readFD != -1) {
            break;
        }
        else if((*readFD == -1) && (errno == EAGAIN)) {
            serial_delay(1000000);
        }
        else {
            return -1;
        }
    }
    if(*readFD == -1) {
        return -1;
    }
    
    for(int i = 0; i < 3; i++) {
        *writeFD = open(dev, O_WRONLY | O_NOCTTY);
        *err = errno;
        if(*writeFD != -1) {
            break;
        }
        else if((*writeFD == -1) && (errno == EAGAIN)) {
            serial_delay(1000000);
        }
        else {
            close(*readFD);
            *readFD = -1;
            return -1;
        }
    }
    if(*writeFD == -1) {
        close(*readFD);
        *readFD = -1;
        return -1;
    }
    /* prepare attributes */
    r = tcgetattr(*writeFD, &my_tios);
    if(r == -1) {
        *err = errno;
        close(*readFD);
        close(*writeFD);
        return -1;
    }
    *pt = my_tios;
    cfmakeraw(&my_tios);
    my_tios.c_iflag |= IGNBRK | INPCK;
    my_tios.c_cflag |= (CS8 | CLOCAL | CREAD | PARENB);
    cfsetispeed(&my_tios, B38400); // dummy
    cfsetospeed(&my_tios, B38400); // dummy    

    r = tcsetattr(*readFD, TCSANOW, &my_tios);
    if(r == -1) {
        *err = errno;
        r = tcsetattr(*writeFD, TCSANOW, pt);
        close(*readFD);
        close(*writeFD);
        return -1;        
    }
    
    /* hack for baudrate */
    r = ioctl(*writeFD, TIOCGSERIAL, &serinfo);
    if(r == -1) {
        *err = errno;
        r = tcsetattr(*writeFD, TCSANOW, pt);
        close(*readFD);
        close(*writeFD);
        return -1;        
    }    
    serinfo.custom_divisor = serinfo.baud_base / 9600;
    if(serinfo.custom_divisor == 0) serinfo.custom_divisor = 1;
    serinfo.flags &= ~ASYNC_SPD_MASK;
    serinfo.flags |= ASYNC_SPD_CUST;
    r = ioctl(*writeFD, TIOCSSERIAL, &serinfo);
    if(r == -1) {
        *err = errno;
        r = tcsetattr(*writeFD, TCSANOW, pt);
        close(*readFD);
        close(*writeFD);
        return -1;        
    }

    // clear buffers
    r = tcflush(*writeFD, TCIOFLUSH);
    if(r == -1) {
        *err = errno;
        r = tcsetattr(*writeFD, TCSANOW, pt);
        close(*readFD);
        close(*writeFD);
        return -1;        
    }
    if(r == -1) {
        *err = errno;
        r = tcsetattr(*writeFD, TCSANOW, pt);
        close(*readFD);
        close(*writeFD);
    }
    return r;
};

int BaseSerial::resetPins(int *err) {
    int r = 0;
    r = setRST(err);
    r = clrTEST(err);
    return r;
}

int BaseSerial::disconnect(int *err) {
    int r;
    if(serialWriteFD != -1) {
        r = resetPins(err);
        if(r == -1) {
            cerr << "WARN: BaseSerial::disconnect could not reset pins, " << strerror(*err) << endl;
        }
        r = tcsetattr(serialWriteFD, TCSANOW, &oldtermios);
    }
    if(serialReadFD != -1) {
        r = close(serialReadFD);
        if(r == -1) {
            *err = errno;
        }
        serialReadFD = -1;
    }
    if(serialWriteFD != -1) {
        r = close(serialWriteFD);
        if(r == -1) {
            *err = errno;
        }
        serialWriteFD = -1;    
    }
    return r;
}

int BaseSerial::reset(int *err) {
    int r = 0;
    r = setRST(err);
    if(r == -1) return -1;
    r = setTEST(err);
    if(r == -1) return -1;
    serial_delay(2500);
    r = clrRST(err);
    if(r == -1) return -1;
    serial_delay(10);
    r = setRST(err);
    if(r == -1) return -1;
    serial_delay(2500);
    cout << "Reset device ..." << endl;
    return clearBuffers(err);
};

int BaseSerial::invokeBsl(int *err) {
    int r = 0;
    r = setRST(err);
    if(r == -1) return -1;
    r = setTEST(err);
    if(r == -1) return -1;
    serial_delay(2500);
    r = clrRST(err);
    if(r == -1) return -1;
    r = setTEST(err);
    if(r == -1) return -1;
    serial_delay(10);
    r = clrTEST(err);
    if(r == -1) return -1;
    serial_delay(10);
    r = setTEST(err);
    if(r == -1) return -1;
    serial_delay(10);
    r = clrTEST(err);
    if(r == -1) return -1;
    serial_delay(10);
    r = setRST(err);
    if(r == -1) return -1;
    serial_delay(10);
    r = setTEST(err);
    if(r == -1) return -1;
    serial_delay(2500);
    cout << "Invoking BSL..." << endl;
    return clearBuffers(err);
}

int BaseSerial::readFD(int *err, char *buffer, int count, int maxCount) {
    int cnt = 0;
    int retries = 0;
    timeval tv;
    tv.tv_sec = 1;
    tv.tv_usec = 0;
    while(cnt == 0) {
        int tmpCnt = read(serialReadFD, buffer, maxCount);
        *err = errno;
        if((tmpCnt == 0) || ((tmpCnt < 0) && (errno == EAGAIN))) {
            FD_SET(serialReadFD, &rfds);
            if(select(serialReadFD + 1, &rfds, NULL, NULL, &tv) < 0) {
                *err = errno;
                return -1;
            }
            FD_CLR(serialReadFD, &rfds);
            if(retries++ >= 3) {
                cerr << "FATAL: BaseSerial::readFD no data available after 3s" << endl;
                return -1;
            }
        }
        else if(tmpCnt > 0) {
            cnt += tmpCnt;
        }
        else {
            return -1;
        }
    }
    return cnt;
}

int BaseSerial::txrx(int *err, frame_t *txframe, frame_t *rxframe) {
    int r = 0;
    char sync = SYNC;
    uint8_t ack = 0;
    if((txframe == NULL) || (txframe->L1 < 4) || ((txframe->L1 & 1) != 0) || (rxframe == NULL)) {
        cerr << "BaseSerial::txrx: precondition not fulfilled, "
             << " txFrame: " << txframe
             << " rxFrame: " << rxframe
             << " txframe->L1: " << (unsigned) txframe->L1
             << endl;
        return -1;
    }
    for(unsigned i = 0; i < 3; i++) {
        r = write(serialWriteFD,&sync, 1);
        if(r == -1) {
            *err = errno;
            if(errno != EAGAIN) return -1;
        }
        r = readFD(err, (char *)(&ack),1,1);
        if(r == 1) {
            if(ack == DATA_ACK) {
                r = 0;
                break;
            }
            else {
                cerr << "WARN: BaseSerial::txrx: received " << hex << (unsigned) ack
                     << " when trying to sync with node." << dec << endl;
            }
        }
        else {
            if((r == -1) && (errno == EAGAIN)) {
                // retry to sync
            }
            else {
                cerr << "FATAL: BaseSerial::txrx could not SYNC with node" << endl;
                return -1;
            }
        } 
    }
    if(r == -1) {
        return -1;
    }
    r = clearBuffers(err); 
    if(r == -1) return r;
    // transmit frame
    checksum(txframe);    
    r = write(serialWriteFD, (char *)txframe, txframe->L1 + 6);
    if(r < txframe->L1 + 6) {
        *err = errno;
        return -1;
    }
    // receive response
    int len = 0;
    rxframe->L1 = 4;
    r = 0;
    while(r >= 0) {
        r = readFD(err, (char *)rxframe, sizeof(frame_t), sizeof(frame_t));
        if(r == -1) {
            return -1;
        }
        else if(r >= 1) {
            len += r;
            if(rxframe->HDR == DATA_ACK) {
                break;
            }            
            else if(rxframe->HDR == DATA_NAK) {
                cerr << "BaseSerial::txrx frame not valid, command "
                     << hex << (unsigned) txframe->CMD << dec 
                     << " not defined or not allowed" << endl;
                return -1;
            }
            else if(rxframe->HDR == SYNC) {
                if(len >= rxframe->L1 + 6) {
                    break;
                }
            }
            else {
                cerr << "FATAL: BaseSerial::txrx: received "
                     << hex << (unsigned) rxframe->HDR
                     << " when trying to execute " << hex << (unsigned) txframe->CMD << dec << endl;
                break;
            }
        }
    }
    return r;
}

int BaseSerial::highSpeed(int *err) {
    struct serial_struct serinfo;
    int r = ioctl(serialWriteFD, TIOCGSERIAL, &serinfo);
    if(r == -1) {
        *err = errno;
        return -1;
    }
    serinfo.custom_divisor = serinfo.baud_base / 38400;
    if(serinfo.custom_divisor == 0) serinfo.custom_divisor = 1;
    serinfo.flags &= ~ASYNC_SPD_MASK;
    serinfo.flags |= ASYNC_SPD_CUST;
    r = ioctl(serialWriteFD, TIOCSSERIAL, &serinfo);
    if(r == -1) {
        *err = errno;
        return -1;
    }
    return r;
}

int TelosBSerial::reset(int *err) {
    int r;
    r = telosI2CWriteCmd(err, 0, 0);
    if(r == -1) return r;
    serial_delay(10000);
    r = telosI2CWriteCmd(err, 0, 3);
    if(r == -1) return r;
    r = telosI2CWriteCmd(err, 0, 2);
    if(r == -1) return r;
    r = telosI2CWriteCmd(err, 0, 0);
    if(r == -1) return r;
    r = telosI2CWriteCmd(err, 0, 0);
    if(r == -1) return r;
    serial_delay(2500);
    cout << "Reset device ..." << endl;
    return clearBuffers(err);
}

int TelosBSerial::invokeBsl(int *err) {
    int r;
    r = telosI2CWriteCmd(err, 0, 0);
    if(r == -1) return r;
    serial_delay(10000);
    r = telosI2CWriteCmd(err, 0, 1);
    if(r == -1) return r;
    r = telosI2CWriteCmd(err, 0, 3);
    if(r == -1) return r;
    r = telosI2CWriteCmd(err, 0, 1);
    if(r == -1) return r;
    r = telosI2CWriteCmd(err, 0, 3);
    if(r == -1) return r;
    r = telosI2CWriteCmd(err, 0, 2);
    if(r == -1) return r;
    r = telosI2CWriteCmd(err, 0, 0);
    if(r == -1) return r;
    r = telosI2CWriteCmd(err, 0, 0);
    if(r == -1) return r;
    serial_delay(2500);
    cout << "Invoking BSL..." << endl;
    return clearBuffers(err);
}

int TelosBSerial::telosI2CStart(int *err) {
    int r;
    r = telosSetSDA(err);
    if(r == -1) return -1;
    r = telosSetSCL(err);
    if(r == -1) return -1;
    r = telosClrSDA(err);
    return r;
}

int TelosBSerial::telosI2CStop(int *err) {
    int r;
    r = telosClrSDA(err);
    if(r == -1) return r;
    r = telosSetSCL(err);
    if(r == -1) return r;
    r = telosSetSDA(err);
    return r;
}

int TelosBSerial::telosI2CWriteBit(int *err, bool bit) {
    int r = telosClrSCL(err);
    if(r == -1) return r;
    if(bit) {
        r = telosSetSDA(err);
        if(r == -1) return r;
    } else {
        r = telosClrSDA(err);
        if(r == -1) return r;
    }
    r = telosSetSCL(err);
    if(r == -1) return r;
    r = telosClrSCL(err);
    return r;
}

int TelosBSerial::telosI2CWriteByte(int *err, uint8_t byte) {
    int r;
    r = telosI2CWriteBit(err,  byte & 0x80 );
    if(r == -1) return r;
    r = telosI2CWriteBit(err,  byte & 0x40 );
    if(r == -1) return r;
    r = telosI2CWriteBit(err,  byte & 0x20 );
    if(r == -1) return r;
    r = telosI2CWriteBit(err,  byte & 0x10 );
    if(r == -1) return r;
    r = telosI2CWriteBit(err,  byte & 0x08 );
    if(r == -1) return r;
    r = telosI2CWriteBit(err,  byte & 0x04 );
    if(r == -1) return r;
    r = telosI2CWriteBit(err,  byte & 0x02 );
    if(r == -1) return r;
    r = telosI2CWriteBit(err,  byte & 0x01 );
    if(r == -1) return r;
    return telosI2CWriteBit(err,  0 );
}

int TelosBSerial::telosI2CWriteCmd(int *err, uint8_t addr, uint8_t cmdbyte) {
    int r;
    r = telosI2CStart(err);
    if(r == -1) return r;
    r = telosI2CWriteByte(err,  0x90 | (addr << 1) );
    if(r == -1) return r;
    r = telosI2CWriteByte(err,  cmdbyte );
    if(r == -1) return r;
    return telosI2CStop(err);
}

int TelosBSerial::resetPins(int *err) {
    int r = 0;
    r = setRTS(err);
    r = clrDTR(err);
    return r;
}
