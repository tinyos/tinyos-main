/*
* Copyright (c) 2009 Johns Hopkins University.
* All rights reserved.
*
* Permission to use, copy, modify, and distribute this software and its
* documentation for any purpose, without fee, and without written
* agreement is hereby granted, provided that the above copyright
* notice, the (updated) modification history and the author appear in
* all copies of this source code.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS  `AS IS'
* AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED  TO, THE
* IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR  PURPOSE
* ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR  CONTRIBUTORS
* BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
* CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE,  DATA,
* OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
* CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR  OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
* THE POSSIBILITY OF SUCH DAMAGE.
*/

/**
 * PDC register definitions.
 *
 * @author JeongGil Ko
 */

#ifndef _SAM3UPDCHARDWARE_H
#define _SAM3UPDCHARDWARE_H

/**
 *  PDC Received Pointer Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 462
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint32_t rxptr    : 32;
  } __attribute__((__packed__)) bits;
} periph_rpr_t; 


/**
 *  PDC Receive Counter Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 463
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint16_t rxctr     : 16;
    uint16_t reserved0 : 16;
  } __attribute__((__packed__)) bits;
} periph_rcr_t; 

/**
 *  PDC Transmit Pointer Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 464
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint32_t txptr   :  32;
  } __attribute__((__packed__)) bits;
} periph_tpr_t; 


/**
 *  PDC Transmit Counter Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 464
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint16_t txctr     : 16;
    uint16_t reserved0 : 16;
  } __attribute__((__packed__)) bits;
} periph_tcr_t; 

/**
 *  PDC Received Next Pointer Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 465
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint32_t rxnptr      :  32;
  } __attribute__((__packed__)) bits;
} periph_rnpr_t; 


/**
 *  PDC Receive Next Counter Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 465
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint16_t rxnctr     : 16;
    uint16_t reserved0 : 16;
  } __attribute__((__packed__)) bits;
} periph_rncr_t; 

/**
 *  PDC Transmit Pointer Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 466
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint32_t txnptr    : 32;
  } __attribute__((__packed__)) bits;
} periph_tnpr_t; 


/**
 *  PDC Transmit Next Counter Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 466
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint16_t txnctr    : 16;
    uint16_t reserved0 : 16;
  } __attribute__((__packed__)) bits;
} periph_tncr_t; 

/**
 *  PDC Transfer Control Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 467
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t rxten      :  1;
    uint8_t rxtdis     :  1;
    uint8_t reserved0  :  6;
    uint8_t txten      :  1;
    uint8_t txtdis     :  1;
    uint8_t reserved1  :  6;
    uint16_t reserved2 : 16;
  } __attribute__((__packed__)) bits;
} periph_ptcr_t; 

/**
 *  PDC Transfer Status Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 468
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t rxten       :  1;
    uint8_t reserved0  :  7;
    uint8_t txten       :  1;
    uint8_t reserved1  :  7;
    uint16_t reserved2 : 16;
  } __attribute__((__packed__)) bits;
} periph_ptsr_t; 


/**
 * PDC Register definitions, AT91 ARM Cortex-M3 based Microcontrollers SAM3U
 * Series, Preliminary, p. 461
 */
typedef struct pdc
{
  volatile periph_rpr_t rpr;
  volatile periph_rcr_t rcr;
  volatile periph_tpr_t tpr;
  volatile periph_tcr_t tcr;
  volatile periph_rnpr_t rnpr;
  volatile periph_rncr_t rncr;
  volatile periph_tnpr_t tnpr;
  volatile periph_tncr_t tncr;
  volatile periph_ptcr_t ptcr;
  volatile periph_ptsr_t ptsr;
} periph_t;


#endif // _SAM3UPDCHARDWARE_H
