/*
 * Copyright (c) 2006 Washington University in St. Louis.
 * All rights reserved.
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
 * @version $Revision: 1.2 $
 * @date $Date: 2010-06-29 22:07:50 $
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

