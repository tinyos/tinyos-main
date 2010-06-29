/*
 * Copyright (c) 2005 Stanford University. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * The C functions representing the TOSSIM binary interference
 * model.
 *
 * @author Philip Levis
 * @date   Nov 22 2005
 */


// $Id: sim_binary.h,v 1.5 2010-06-29 22:07:51 scipio Exp $



#ifndef SIM_BINARY_H_INCLUDED
#define SIM_BINARY_H_INCLUDED


#ifdef __cplusplus
extern "C" {
#endif

  typedef struct link {
    int mote;
    double loss;
    struct link* next;  
  } link_t;
  
  void sim_binary_add(int src, int dest, double packetLoss);
  double sim_binary_loss(int src, int dest);
  bool sim_binary_connected(int src, int dest);
  void sim_binary_remove(int src, int dest);

  link_t* sim_binary_first(int src);
  link_t* sim_binary_next(link_t* link);
  
#ifdef __cplusplus
}
#endif
  
#endif // SIM_BINARY_H_INCLUDED
