/*
 * Copyright (c) 2008, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions 
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright 
 *   notice, this list of conditions and the following disclaimer in the 
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names 
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.2 $
 * $Date: 2009-03-04 18:31:42 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

/** 
 * MLME-SAP synchronization primitives define how synchronization with
 * a coordinator may be achieved and how a loss of synchronization is
 * communicated to the next higher layer. (IEEE 802.15.4-2006, Sect.
 * 7.1.15)
 */

interface MLME_SYNC {

  /**
   * Requests to synchronize with the coordinator by acquiring and, if
   * specified, tracking its beacons.
   * 
   * @param LogicalChannel Logical channel on which to attempt coordinator
   *                       synchronization
   * @param ChannelPage The channel page on which to attempt coordinator
   *                    synchronization.
   * @param TrackBeacon TRUE if the MLME is to synchronize with the next
   *                    beacon and attempt to track all future beacons.
   *                    FALSE if the MLME is to synchronize with only the
   *                    next beacon.
   * @return       IEEE154_SUCCESS if the request succeeded and the device
   *               is now trying to acquire synchronization with the coordinator.
   *               Note: the MLME_SYNC_LOSS interface is used to signal
   *               when synchronization was lost (or never acquired)
   */
  command ieee154_status_t request  (
                          uint8_t LogicalChannel,
                          uint8_t ChannelPage,
                          bool TrackBeacon
                        );

}
