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

#include <fstream>
#include <iostream>
#include "Parameters.h"
#include "Serial.h"
#include "Bsl.h"

using namespace std;

Parameters *parameters;

void errMsg(int r, int err, const char *msg) {
    cerr << msg;
    if(err) {
        cerr << ", system error: " << strerror(err);
    } else {
        cerr << ", internal error";
    }
    cerr << "." << endl;
}

int main(int argc, char *argv[]) {
    int r, readFD, writeFD, err;
    termios oldterm;
    parameters = new Parameters(argc, argv);
    BaseSerial *bs;
    Bsl *bsl;
    err = 0;
    r = serial_connect(&err, parameters->dev.c_str(), &readFD, &writeFD, &oldterm);
    if(r == -1) {
        errMsg(r, err, "Could not connect to serial device");
        delete parameters;
        return -1;
    }
    if(parameters->telosb) {
        bs = new TelosBSerial(oldterm, readFD, writeFD);
    }
    else {
        bs = new BaseSerial(oldterm, readFD, writeFD, parameters->invertTest, parameters->invertReset);
    }
    bsl = new Bsl(bs, parameters->img.c_str());
    switch(parameters->action) {
        case Parameters::ERASE:
            r = bsl->erase(&err);
            if(r == -1) {
                errMsg(r, err, "Could not erase node");
            }
            else {
                r = bsl->reset(&err);
                if(r == -1) {
                    errMsg(r, err, "Could not reset node");
                }    
            }
            break;
        case Parameters::RESET:
            r = bsl->reset(&err);
            if(r == -1) {
                errMsg(r, err, "Could not reset node");
            }
            break;
        case Parameters::FLASH:
            r = bsl->install(&err);
            if(r == -1) {
                errMsg(r, err, "Could not install image on node");
            }
            break;
        default:
            break;
    }
    delete bsl;
    bs->disconnect(&err);
    delete bs;
    delete parameters;
    return 0;
}
