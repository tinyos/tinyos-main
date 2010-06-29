/* $Id: CollectionDebug.nc,v 1.5 2010-06-29 22:07:47 scipio Exp $*/
/*
 * Copyright (c) 2005 The Regents of the University  of California.  
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
 * - Neither the name of the University of California nor the names of
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

/** 
 *  The CollectionDebug is an interface for sending debugging events to
 *  a logging infrastructure. An implementer can choose to send the event
 *  information to different destinations. Primary examples can include:
 *  <ul>
 *    <li> logging to the UART, in case of a testbed of network-connected
 *         nodes;
 *    <li> logging to flash, if the logs are to be retrieved later
 *    <li> logging to the standard output, in the case of TOSSIM.
 *  </ul>
 *  
 *  The interface does not specify in what format the log is to be produced,
 *  or if other information, like timestamps, should be added, and this is
 *  up to the implementer.
 * 
 *  Some commands are generic, like Event, EventSimple, and EventDbg, while others
 *  are for more specific events related to collection, like EventRoute and EventMsg.
 *
 
 * @author Rodrigo Fonseca
 * @author Kyle Jamieson
 * @date   $Date: 2010-06-29 22:07:47 $
 */

interface CollectionDebug {
    /* Log the occurrence of an event of type type */
    command error_t logEvent(uint8_t type);

    /* Log the occurrence of an event and a single parameter */
    command error_t logEventSimple(uint8_t type, uint16_t arg);

    /* Log the occurrence of an event and 3 16bit parameters */
    command error_t logEventDbg(uint8_t type, uint16_t arg1, uint16_t arg2, uint16_t arg3);

    /* Log the occurrence of an event related to forwarding a message.
     * This is intended to allow following the same message as it goes from one
     * hop to the next 
     */
    command error_t logEventMsg(uint8_t type, uint16_t msg, am_addr_t origin, am_addr_t node);

    /* Log the occurrence of an event related to a route update message, 
     * such as a node receiving a route, updating its own route information,
     * or looking at a particular entry in its routing table.
     */
    command error_t logEventRoute(uint8_t type, am_addr_t parent, uint8_t hopcount, uint16_t metric);
}
