// $Id: GainRadioModel.nc,v 1.4 2006-12-12 18:23:32 vlahan Exp $
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
 * The interface to a gain-based radio model, which considers
 * signal strength of transmission and propagation. It also
 * includes a clear channel estimate. The actual implementation
 * of the model (e.g., noise, signal collision) is generally
 * C-based.
 *
 * @author Philip Levis
 * @date   December 2 2005
 */ 


#include "TinyError.h"

interface GainRadioModel {
  command void putOnAirTo(int dest,
			  message_t* msg,
			  bool ack,
			  sim_time_t endTime,
			  double gain);

  command void setClearValue(double value);
  command bool clearChannel();
  
  event void acked(message_t* msg);
  event void receive(message_t* msg);
  event bool shouldAck(message_t* msg);
}
