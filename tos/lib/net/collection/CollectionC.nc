/* $Id: CollectionC.nc,v 1.4 2006-12-12 18:23:29 vlahan Exp $ */
#include "Collection.h"
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

/*
 *  @author Rodrigo Fonseca
 *  @date   $Date: 2006-12-12 18:23:29 $
 */
configuration CollectionC {
    provides {
        interface SplitControl;
        interface Send;
        interface Receive;
        interface Receive as Snoop;
        interface Intercept;
        interface Packet;
        interface RootControl;
    }
}

implementation {
  components new ForwardingEngineP(), new TreeRoutingEngineP(8), LinkEstimatorC;
    
  Send = ForwardingEngineP;
  Receive = ForwardingEngineP;
  Snoop = ForwardingEngineP;
  Intercept = ForwardingEngineP;
  Packet = ForwardingEngineP;
  RootControl = TreeRoutingEngineP;
  
  ForwardingEngineP.BasicRouting -> TreeRoutingEngineP;
  TreeRoutingEngineP.LinkEstimator -> LinkEstimatorC;
  ForwardingEngineP.LinkEstimator -> LinkEstimatorC;
  
  components new LinkEstimatorAMSenderC(AM_COLLECTION_DATA) 
    as DataAMSender; 
  ForwardingEngineP.AMSend -> DataAMSender;
  
  components new LinkEstimatorAMReceiverC(AM_COLLECTION_DATA) 
    as DataAMReceiver;
  ForwardingEngineP.AMReceive -> DataAMReceiver;
  
  components new LinkEstimatorAMSenderC(AM_COLLECTION_CONTROL) 
    as ControlAMSender; 
  TreeRoutingEngineP.AMSend -> ControlAMSender;
  
  components new LinkEstimatorAMReceiverC(AM_COLLECTION_CONTROL)
    as ControlAMReceiver;
  TreeRoutingEngineP.AMReceive -> ControlAMReceiver;     
}
