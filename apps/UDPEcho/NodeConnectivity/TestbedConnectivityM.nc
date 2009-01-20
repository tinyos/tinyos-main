/*
 * "Copyright (c) 2008 The Regents of the University  of California.
 * All rights reserved."
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
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
