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
 * The C functions representing the TOSSIM binary interference
 * model.
 *
 * @author Philip Levis
 * @date   Nov 22 2005
 */


// $Id: sim_binary.h,v 1.4 2006-12-12 18:23:35 vlahan Exp $



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
