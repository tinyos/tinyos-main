/**
 * Copyright (c) 2005-2006 Arch Rock Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Arch Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */
/* 
 * Copyright (c) 2006, Ecole Polytechnique Federale de Lausanne (EPFL),
 * Switzerland.
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
 * - Neither the name of the Ecole Polytechnique Federale de Lausanne (EPFL) 
 *   nor the names of its contributors may be used to 
 *   endorse or promote products derived from this software without 
 *   specific prior written permission.
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
 * ========================================================================
 */

/**
 * @author Jonathan Hui <jhui@archrock.com>
 * @author Henri Dubois-Ferriere
 * @version $Revision: 1.5 $ $Date: 2007-07-13 15:54:08 $
 */

module XE1205SpiImplP {

    provides interface XE1205Fifo as Fifo @atmostonce();
    provides interface XE1205Register as Reg[uint8_t id];

    provides interface Init @atleastonce();

    provides interface Resource[ uint8_t id ];

    uses interface Resource as SpiResource;
    uses interface GeneralIO as NssDataPin;
    uses interface GeneralIO as NssConfigPin;
    uses interface SpiByte;
    uses interface SpiPacket;
}

implementation {

#include "xe1205debug.h"

    enum {
	RESOURCE_COUNT = uniqueCount( "XE1205Spi.Resource" ),
	NO_HOLDER = 0xff,
    };


    bool m_resource_busy = FALSE;
    uint8_t m_requests = 0;
    uint8_t m_holder = NO_HOLDER;

    command error_t Init.init() {
	call NssDataPin.makeOutput();
	call NssConfigPin.makeOutput();
	call NssDataPin.set();
	call NssConfigPin.set();
	return SUCCESS;
    }

    async command error_t Resource.request[ uint8_t id ]() {
	atomic {
	    if ( m_resource_busy )
		m_requests |= 1 << id;
	    else {
		m_holder = id;
		m_resource_busy = TRUE;
		
		call SpiResource.request();
	    }
	}
	return SUCCESS;
    }
  
    async command error_t Resource.immediateRequest[ uint8_t id ]() {
	error_t error;
	atomic {
	    if ( m_resource_busy )
		return EBUSY;
	    error = call SpiResource.immediateRequest();
	    if ( error == SUCCESS ) {
		m_holder = id;
		m_resource_busy = TRUE;

	    }
	    xe1205check(9, error);
	}
	return error;
    }

    async command error_t Resource.release[ uint8_t id ]() {
	uint8_t i;
	atomic {
	    if ( m_holder != id ) {
		xe1205check(11, 1);
		return FAIL;
	    }

	    m_holder = NO_HOLDER;
	    call SpiResource.release();
	    if ( !m_requests ) {
		m_resource_busy = FALSE;

	    }
	    else {
		for ( i = m_holder + 1; ; i++ ) {
		    if ( i >= RESOURCE_COUNT )
			i = 0;
		    if ( m_requests & ( 1 << i ) ) {
			m_holder = i;
			m_requests &= ~( 1 << i );
			call SpiResource.request();
			return SUCCESS;
		    }
		}
	    }
	    return SUCCESS;
	}
    }
  
    async command bool Resource.isOwner[ uint8_t id ]() {
	atomic return (m_holder == id);
    }

    event void SpiResource.granted() {
	uint8_t holder;
	atomic holder = m_holder;
	signal Resource.granted[ holder ]();
    }


 default event void Resource.granted[ uint8_t id ]() {
 }

 async command error_t Fifo.write(uint8_t* data, uint8_t length) __attribute__ ((noinline)){

#if 0
     if (call NssDataPin.get() != TRUE || call NssConfigPin.get() != TRUE)
	 xe1205check(8, 1);
#endif


     call SpiPacket.send(data, NULL, length);

     return SUCCESS;
 }

 async event void SpiPacket.sendDone(uint8_t* tx_buf, uint8_t* rx_buf, 
				     uint16_t len, error_t error) 
 {

#if 0
     if (call NssConfigPin.get() != TRUE) xe1205check(4, 1);
     if (call NssDataPin.get() != FALSE) xe1205check(12, 1);
#endif
     TOSH_SET_NSS_DATA_PIN();
     if (tx_buf) {

	 signal Fifo.writeDone(error);
     } else
	 signal Fifo.readDone(error);
 }

 async command error_t Fifo.read(uint8_t* data, uint8_t length) {
     error_t status;

#if 0
     if (call NssDataPin.get() != TRUE || call NssConfigPin.get() != TRUE)
	 xe1205check(5, 1);
#endif

     TOSH_CLR_NSS_DATA_PIN();
     status = call SpiPacket.send(NULL, data, length);
     if (status != SUCCESS) {
	 xe1205check(3, status);
	 call NssDataPin.set();
	 return status;
     }
     return SUCCESS;
 }

 async command void Reg.read[uint8_t addr](uint8_t* data) 
 {
#if 1
     if (call NssDataPin.get() != TRUE || call NssConfigPin.get() != TRUE)
	 xe1205check(6, 1);
#endif

     call NssDataPin.set();
     call NssConfigPin.clr();
     call SpiByte.write(XE1205_READ(addr));
     *data = call SpiByte.write(0);
     call NssConfigPin.set();
 }

 async command void Reg.write[uint8_t addr](uint8_t data) 
 {
#if 1
     if (call NssDataPin.get() != TRUE || call NssConfigPin.get() != TRUE)
	 xe1205check(7, 1);
#endif

     call NssDataPin.set();
     call NssConfigPin.clr();
     call SpiByte.write(XE1205_WRITE(addr));
     call SpiByte.write(data);
     call NssConfigPin.set();
 }

 default async event void Fifo.readDone(error_t error) {}
 default async event void Fifo.writeDone(error_t error) {}
}
