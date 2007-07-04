/*
 * "Copyright (c) 2005 Stanford University. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL STANFORD UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF STANFORD UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 * 
 * STANFORD UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND STANFORD UNIVERSITY
 * HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
 * ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 *
 * Injecting packets into TOSSIM.
 *
 * @author Philip Levis
 * @date   Dec 10 2005
 */

#ifndef PACKET_H_INCLUDED
#define PACKET_H_INCLUDED

#include <sim_packet.h>

class Packet {
  public:
    Packet();
    Packet(sim_packet_t* msg);
    ~Packet();

    void setSource(int src);
    int source();

    void setDestination(int dest);
    int destination();

    void setLength(int len);
    int length();

    void setType(int type);
    int type();

    char* data();
    void setData(char* data, int len);
    int maxLength();
    
    void setStrength(int str);

    sim_packet_t* getPacket();

    void deliver(int node, long long int t);
    void deliverNow(int node);
    
 private:
    int allocated;
    sim_packet_t* msgPtr;
};

#endif
