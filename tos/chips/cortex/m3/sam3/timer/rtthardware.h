/**
 * Copyright (c) 2009 The Regents of the University of California.
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
 * - Neither the name of the copyright holders nor the names of its
 *   contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 * WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * Real-Time Timer register definitions.
 *
 * @author Thomas Schmid
 */

#ifndef RTTHARDWARE_H
#define RTTHARDWARE_H

typedef union
{
    uint32_t flat;
    struct
    {
        uint16_t rtpres    : 16; // RTT prescaler
        uint8_t almien     :  1; // alarm interrupt enable
        uint8_t rttincien  :  1; // RTT increment interrupt enable
        uint8_t rttrst     :  1; // RTT restart
        uint8_t reserved1  :  5;
        uint8_t reserved0  :  8;
    } bits;
} rtt_mr_t;

/* Note: Never read directly the status register since it gets reset after
 * each read. Thus, you migh tmiss an interrupt!
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t alms       :  1; // RT alarm status
        uint8_t rttinc     :  1; // RTT increment status
        uint8_t reserved2  :  6;
        uint8_t reserved1  :  8;
        uint16_t reserved0 : 16;
    } bits;
} rtt_sr_t;

// Real Time Timer Register definition
typedef struct rtt 
{
    volatile rtt_mr_t mr;	// Real Time Mode Register
    volatile uint32_t   ar;	// Real Time Alarm Register
    volatile uint32_t   vr;	// Real Time Value Register
    volatile rtt_sr_t sr;	// Real Time Status Register
} rtt_t;

#endif // RTTHARDWARE_H
