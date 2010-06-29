/*
 * Copyright (c) 2008 The Regents of the University  of California.
 * All rights reserved."
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
 * - Neither the name of the copyright holders nor the names of
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
 *
 */
// Filename: NodeConnectivityM.nc
// Generated on Wed Jun 11 19:54:54 UTC 2008

// Created by createMotelabTopology.pl

module TestbedConnectivityM {
  provides {
    interface NodeConnectivity;
  }
} implementation {
  uint8_t connectivity[8][8] =
  {
    { 1, 1, 0, 0, 0, 0, 0, 0 },
    { 1, 1, 1, 0, 0, 0, 0, 0 },
    { 0, 1, 1, 1, 0, 0, 0, 0 },
    { 0, 0, 1, 1, 1, 0, 0, 0 },
    { 0, 0, 0, 1, 1, 1, 0, 0 },
    { 0, 0, 0, 0, 1, 1, 1, 0 },
    { 0, 0, 0, 0, 0, 1, 1, 1 },
    { 0, 0, 0, 0, 0, 0, 1, 1 }
  };
  uint16_t mapping[8] = { 100, 101, 102, 37, 35, 33, 32, 106 };
  
  command int8_t NodeConnectivity.mapping(uint16_t moteid) {
    uint8_t i;
    for (i = 0; i < 8; i++) {
      if (mapping[i] == moteid) {
        return i;
      }
    }
    return -1;
  }

  command bool NodeConnectivity.connected(uint16_t srcnode, uint16_t dstnode) {
    int8_t src = call NodeConnectivity.mapping(srcnode);
    int8_t dst = call NodeConnectivity.mapping(dstnode);

    if ((src == -1) ||
        (dst == -1)) {
      return FALSE;
    }

    if (connectivity[src][dst] == 1) {
      return TRUE;
    } else {
      return FALSE;
    }
  }
}
