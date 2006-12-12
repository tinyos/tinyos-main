/* $Id: CtpDebug.nc,v 1.4 2006-12-12 18:23:29 vlahan Exp $*/
/*
 * "Copyright (c) 2005 The Regents of the University  of California.  
 * All rights reserved.
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
 * @date   $Date: 2006-12-12 18:23:29 $
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
