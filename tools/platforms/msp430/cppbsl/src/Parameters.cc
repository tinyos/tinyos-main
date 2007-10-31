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
#include "cmdline.h"
#include "Parameters.h"

using namespace std;

Parameters::Parameters(int argc, char **argv) {
    action = NONE;
    gengetopt_args_info args_info;
    cmdline_parser_init(&args_info);    
    if(cmdline_parser(argc, argv, &args_info) != 0) {
        exit(1);
    }
    if(args_info.invert_test_given) {
        invertTest = true;
    } else {
        invertTest = false;
    }
    if(args_info.invert_reset_given) {
        invertReset = true;
    } else {
        invertReset = false;
    }
    if(args_info.debug_given) {
        verbose = true;
    } else {
        verbose = false;
    }
    if((args_info.erase_given) && (action < ERASE)) {
        action = ERASE;
    }
    if((args_info.reset_given) && (action < RESET)) {
        action = RESET;
    }
    if(args_info.program_given) {
        action = FLASH;
        img = args_info.program_arg;
    }
    if(args_info.comport_given) {
        dev = args_info.comport_arg;
    }
    if(args_info.telosb_given  || args_info.tmote_given) {
        telosb = true;
        invertReset = false;
        invertTest = false;
    }
    cmdline_parser_free(&args_info);
};






