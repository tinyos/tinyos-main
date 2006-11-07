/* -*- mode:c++ -*-
 * Copyright (c) 2004, Technische Universitaet Berlin
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
 * $Revision: 1.3 $
 * $Date: 2006-11-07 19:31:23 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

/** 
 *
 * Please refer to TEP 109 for more information about this component and its
 * intended use. This component provides platform-independent access to the
 * RSSI sensor exported by the TDA5250 radio on the eyesIFXv{1,2} platform.
 * Note: The radio must be configured to output the RSSI on the pin!
 *
 * @author Jan Hauer
 */

#include <sensors.h>

module RssiSensorVccP
{
    provides {
        interface ReadNow<uint16_t> as ReadNow;
        interface Resource as ReadNowResource;
    }
    uses {
        interface Resource as SubResource;
        interface Msp430Adc12SingleChannel as SingleChannel;
    }
}
implementation
{
    async command error_t ReadNow.read() {
        return call SingleChannel.getData();
    }
    
    async event error_t SingleChannel.singleDataReady(uint16_t data) {
      signal ReadNow.readDone(SUCCESS, data);
      return FAIL;  
    }

    async event uint16_t* SingleChannel.multipleDataReady(uint16_t buffer[], uint16_t numSamples){
      return 0;
    }
    
    async command error_t ReadNowResource.request() {
        return call SubResource.request();
    }
    
    async command error_t ReadNowResource.immediateRequest() {
        error_t res = call SubResource.immediateRequest();
        if(res == SUCCESS) {
            res = call SingleChannel.configureSingle(&sensorconfigurations[RSSI_SENSOR_VCC]);
            if(res != SUCCESS) call SubResource.release();
        }
        return res;
    }

    event void SubResource.granted() {
        call SingleChannel.configureSingle(&sensorconfigurations[RSSI_SENSOR_VCC]);
        signal ReadNowResource.granted();
    }

    async command error_t ReadNowResource.release() {
        return call SubResource.release();
    }
    
    async command bool ReadNowResource.isOwner() {
        return call SubResource.isOwner();
    }
}
