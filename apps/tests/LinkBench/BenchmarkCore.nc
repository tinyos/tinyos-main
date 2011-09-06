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

#include "BenchmarkCore.h"

interface BenchmarkCore {
  
  /**
   * Requests a statistics indexed by 'index'
   * @return the stat
   */
  command stat_t* getStat(uint16_t idx);
  
  /**
   * Requests the profile information
   * @return the mote stat structure
   */
  command profile_t* getProfile();
  
  /**
   * Requests the current edge count 
   * @return the edge count of the current problem
   */
  command uint8_t getEdgeCount();
  
  /**
   * Requests the maximal mote id present in the current benchmark
   * @return the maximal mote id
   */
  command uint8_t getMaxMoteId();
  
  
  /** Configures the benchmark core with 'conf' */
  command void setup(setup_t conf);
  
  /** Indicates the successfull configuration of the benchmark */
  event void setupDone();
  
  /** Resets the benchmarking core component */
  command void reset();

  /** Indicates the finish of the reset operation */
  event void resetDone();
  
  /** Indicates the finish of the benchmark */
  event void finished();
  
  
}
