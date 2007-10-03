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
 * SWIG interface specification for delivering packets to a node
 * (injecting traffic).
 *
 * Note that changing this file only changes the Python interface:
 * you must also change the underlying TOSSIM code so Python
 * has the proper functions to call. Look at mac.h, mac.c, and
 * sim_mac.c.
 *
 * @author Philip Levis
 * @author Chad Metcalf
 * @date   July 17 2007
 */


%{
#include <SerialPacket.h>
%}

%apply (char *STRING, int LENGTH) { (char *data, int len) };

class SerialPacket {
  public:
    SerialPacket();
    ~SerialPacket();

    void setDestination(int dest);
    int destination();

    void setLength(int len);
    int length();

    void setType(int type);
    int type();

    char* data();

    void setData(char* data, int len);
    int maxLength();
    
    void deliver(int node, long long int time);
    void deliverNow(int node);
};
