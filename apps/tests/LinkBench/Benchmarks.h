/*
* Copyright (c) 2010, University of Szeged
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions
* are met:
*
* - Redistributions of source code must retain the above copyright
* notice, this list of conditions and the following disclaimer.
* - Redistributions in binary form must reproduce the above
* copyright notice, this list of conditions and the following
* disclaimer in the documentation and/or other materials provided
* with the distribution.
* - Neither the name of University of Szeged nor the names of its
* contributors may be used to endorse or promote products derived
* from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
* FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
* COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
* INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
* SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
* HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
* STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
* OF THE POSSIBILITY OF SUCH DAMAGE.
*
* Author: Krisztian Veress
*         veresskrisztian@gmail.com
*/

#ifndef BENCHMARKS_H
#define BENCHMARKS_H

#include "BenchmarkCore.h"
#include <AM.h>

// Every benchmark can be numbered when defining it
// This number is hidden in a separator edge right between the 
// benchmark's own edges
#define _BMARK_START_(id) {INVALID_SENDER,(id),{0,0},{0,0,0,0,0},{0,0},0,0},  
#define _BMARK_END_ ,

#define PROBLEMSET_END    {INVALID_SENDER,0,{0,0},{0,0,0,0,0},{0,0},0,0}

#define INVALID_SENDER  AM_BROADCAST_ADDR
#define ALL             AM_BROADCAST_ADDR

#define REPLY_ON(POS) (1<<(POS))
#define NUM(QTY) {(QTY), (QTY)}

#define NO_REPLY      0
#define START_MSG_ID  1
#define NO_TIMER      {0,0}

#define TIMER(X)      ((X)-1)

edge_t problemSet[] = {

#ifndef EXCLUDE_STANDARD
#include "StandardBenchmarks.h"
#endif

#ifndef EXCLUDE_USERDEFINED
#include "UserdefinedBenchmarks.h"
#endif

  PROBLEMSET_END
}; // problemSet END

#endif
