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
 * $Revision: 1.1 $
 * $Date: 2008-06-16 18:00:31 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

#include "TKN154.h"
interface MLME_SCAN 
{

  /**
   * Initializes a channel scan over a given list of channels.
   * 
   * If the PIB attribute <tt>macAutoRequest</tt> is set to FALSE, then
   * for each received beacon a PAN descriptor is signalled to the next higher
   * layer through a separate <tt>MLME_BEACON_NOTIFY.indication()</tt> 
   * event; otherwise the result of the channel scan is stored in a user
   * allocated buffer, either <tt>EnergyDetectList</tt> or 
   * <tt>PANDescriptorList</tt> depending on <tt>ScanType</tt>, and the 
   * buffer is returned when the scan is completed.
   *
   * Both of the parameters <tt>EnergyDetectList</tt> and 
   * <tt>PANDescriptorList</tt> may be NULL, but at least one of them 
   * must be NULL.
   *
   * @param ScanType The type of scan performed: ENERGY_DETECTION_SCAN,
   *                 ACTIVE_SCAN, PASSIVE_SCAN or ORPHAN_SCAN
   * @param ScanChannels The 27 LSBs indicate which channels are to be
   *                     scanned (1 = scan, 0 = don't scan)
   * @param ScanDuration Value used to calculate the length of time to
   *                     spend scanning each channel for ED, active, and
   *                     passive scans.  This parameter is ignored for
   *                     orphan scans.
   * @param ChannelPage The channel page on which to perform the scan
   * @param EnergyDetectListNumEntries The number of entries in the 
   *                    <tt>EnergyDetectList</tt>.
   * @param EnergyDetectList An empty buffer (allocated by the caller)  
   *                    to store the result of the energy measurements  
   *                    or NULL if the result should not be stored
   * @param PANDescriptorListNumEntries The number of entries in the
   *                    <tt>PANDescriptorList</tt>.
   * @param PANDescriptorList An empty buffer (allocated by the caller)   
   *                     to store the result of the active/passive scan 
   *                     or NULL if the result should not be stored
   * @param security    The security options (NULL means security is 
   *                    disabled)
   * @return       IEEE154_SUCCESS if the request succeeded and a confirm event
   *               will be signalled, an appropriate error code otherwise 
   *               (no confirm event will be signalled in this case)
   * @see          confirm
   */
  command ieee154_status_t request  (
                          uint8_t ScanType,
                          uint32_t ScanChannels,
                          uint8_t ScanDuration,
                          uint8_t ChannelPage,
                          uint8_t EnergyDetectListNumEntries,
                          int8_t* EnergyDetectList,
                          uint8_t PANDescriptorListNumEntries,
                          ieee154_PANDescriptor_t* PANDescriptorList,
                          ieee154_security_t *security
                        );

  /**
   * Reports the results of the channel scan request, returning
   * the buffers passed in the <tt>request</tt> command.
   *
   * @param status The status of the scan request
   * @param ScanType The type of scan performed
   * @param ChannelPage The channel page on which the scan
   *                    was performed (see 6.1.2).
   * @param UnscannedChannels The 27 LSBs indicate which channels are not
   *                    scanned (0 = scanned, 1 = not scanned)
   * @param EnergyDetectNumResults The number of valid entries in the 
   *                    <tt>EnergyDetectList</tt>.
   * @param EnergyDetectList The buffer list of energy measurements, one for 
   *                    each channel searched during an ED scan
     @param PANDescriptorListNumResults The number of valid entries in the
   *                    <tt>PANDescriptorList</tt>.
   * @param PANDescriptorList The list of PAN descriptors, one for each
   *                    unique beacon found during an active or passive scan
   */
  event void confirm    (
                          ieee154_status_t status,
                          uint8_t ScanType,
                          uint8_t ChannelPage,
                          uint32_t UnscannedChannels,
                          uint8_t EnergyDetectNumResults,
                          int8_t* EnergyDetectList,
                          uint8_t PANDescriptorListNumResults,
                          ieee154_PANDescriptor_t* PANDescriptorList
                        );

}
