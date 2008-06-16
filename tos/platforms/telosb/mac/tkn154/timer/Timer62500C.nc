// $Id: Timer62500C.nc,v 1.1 2008-06-16 18:05:14 janhauer Exp $
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
 * The virtualized 62500 Hz timer abstraction. Instantiating this 
 * component gives an 62500 Hz granularity timer.
 *
 * @author Philip Levis
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de> (62500hz)
 * @date   January 16 2006
 * @see    TEP 102: Timers
 */ 

#include "Timer62500hz.h"

generic configuration Timer62500C() {
  provides interface Timer<T62500hz>;
}
implementation {
  components Timer62500P;
  Timer = Timer62500P.Timer62500[unique(UQ_TIMER_62500HZ)];
}

