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

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <iostream>
#include <popt.h>
#include "Parameters.h"

using namespace std;

Parameters::Parameters(int argc, char **argv) {
    int c;
    action = NONE;
    device = 0;
    verbose = false;
    action = NONE;
    image = 0;
    telosb = false;

    poptOption optionsTable[] = {
        {"debug",'D', 0, 0, 'd', "print many statements on progress"},
        {"f1x",'1', 0, 0, '1', "Specify CPU family, in case autodetect fails"},
        {"invert-reset",'R', 0, 0, 'R', "RESET pin is inverted"},
        {"invert-test",'T', 0, 0, 'T', "TEST pin is inverted"},
        {"telosb",'b', 0, 0, 'b', "Assume a TelosB node"},
        {"tmote",'b', 0, 0, 'b', "Assume a Tmote node"},
        {"intelhex",'I', 0, 0, 'I', "force fileformat to be  IntelHex"},
        {"erase",'e', 0, 0, 'e', "erase device"},
        {"reset",'r', 0, 0, 'r', "reset device"},
        {"program",'p', POPT_ARG_STRING, &image, 0,
         "Program file", ""},
        {"comport",'c', POPT_ARG_STRING, &device, 0,
         "communicate with MSP430 using this device", ""},
        POPT_AUTOHELP
        POPT_TABLEEND
    };
    
    poptContext optCon;   /* context for parsing command-line options */
    optCon = poptGetContext(NULL, argc, (const char**)argv, optionsTable, 0);
    /* Now do options processing */
    while((c = poptGetNextOpt(optCon)) >= 0) {
        switch(c) {
            case 'R':
                invertReset = true;
                break;
            case 'T':
                invertTest = true;
                break;
            case 'd':
                verbose = true;
                break;
            case 'r':
                if(action < RESET) {
                    action = RESET;
                }
                break;
            case 'e':
                if(action < ERASE) {
                    action = ERASE;
                }
                break;
            case 'b':
                telosb = true;
                break;
            default:
                break;
        }
    }
    if (c < -1) {
        /* an error occurred during option processing */
        fprintf(stderr, "%s: %s\n",
                poptBadOption(optCon, POPT_BADOPTION_NOALIAS),
                poptStrerror(c));
        exit(1);
    }
    if(telosb) {
        invertReset = false;
        invertTest = false;
    }
    if(image != 0) {
        action = FLASH;
    }
    if(device != 0) {
        dev = device;
    }
    else {
        exit(1);
    }
    if(image != 0) {
        img = image;
    }
    else if(action == FLASH) {
        exit(1);
    }
    poptFreeContext(optCon);
};






