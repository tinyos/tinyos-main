/**
 * "Copyright (c) 2009 The Regents of the University of California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
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
