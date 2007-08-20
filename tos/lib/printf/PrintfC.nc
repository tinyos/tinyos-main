/*
 * "Copyright (c) 2006 Washington University in St. Louis.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL WASHINGTON UNIVERSITY IN ST. LOUIS BE LIABLE TO ANY PARTY
 * FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
 * OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF WASHINGTON
 * UNIVERSITY IN ST. LOUIS HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * WASHINGTON UNIVERSITY IN ST. LOUIS SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND WASHINGTON UNIVERSITY IN ST. LOUIS HAS NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS."
 */

/**
 * This is the PrintfC component.  It provides the printf service for printing
 * data over the serial interface using the standard c-style printf command.  
 * It must be started via the SplitControl interface it provides.  Data
 * printed using printf are buffered and only sent over the serial line after
 * making a call to PrintfFlush.flush().  This buffer has a maximum size of 
 * 250 bytes at present.  After calling start on this component, printf
 * statements can be made anywhere throughout your code, so long as you include
 * the "printf.h" header file in every file you wish to use it.  Standard
 * practice is to start the printf service in the main application, and set up 
 * a timer to periodically flush the printf buffer (500ms should do).  In future
 * versions, user defined buffer sizes as well as well as automatic flushing at 
 * user defined intervals will be supported.  
 *
 * @author Kevin Klues (klueska@cs.wustl.edu)
 * @version $Revision: 1.7 $
 * @date $Date: 2007-08-20 06:09:11 $
 */

#include "printf.h"

configuration PrintfC {
  provides {
  	interface SplitControl as PrintfControl;
  	interface PrintfFlush;
  }
}
implementation {
  components SerialActiveMessageC;
  components new SerialAMSenderC(AM_PRINTF_MSG);
  components PrintfP;

  PrintfControl = PrintfP;
  PrintfFlush = PrintfP;
  
  PrintfP.SerialControl -> SerialActiveMessageC;
  PrintfP.AMSend -> SerialAMSenderC;
  PrintfP.Packet -> SerialAMSenderC;
}

