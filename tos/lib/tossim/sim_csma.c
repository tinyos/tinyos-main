/*
 * "Copyright (c) 2005 Stanford University. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL STANFORD UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF STANFORD UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 * 
 * STANFORD UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND STANFORD UNIVERSITY
 * HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
 * ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 *
 * C implementation of configuration parameters for a CSMA link.
 *
 * @author Philip Levis
 * @date   Dec 10 2005
 */

// $Id: sim_csma.c,v 1.3 2006-11-07 19:31:21 scipio Exp $

#include <sim_csma.h>

int csmaInitHigh = SIM_CSMA_INIT_HIGH;
int csmaInitLow = SIM_CSMA_INIT_LOW;
int csmaHigh = SIM_CSMA_HIGH;
int csmaLow = SIM_CSMA_LOW;
int csmaSymbolsPerSec = SIM_CSMA_SYMBOLS_PER_SEC;
int csmaBitsPerSymbol = SIM_CSMA_BITS_PER_SYMBOL;
int csmaPreambleLength = SIM_CSMA_PREAMBLE_LENGTH;
int csmaExponentBase = SIM_CSMA_EXPONENT_BASE;
int csmaMaxIterations = SIM_CSMA_MAX_ITERATIONS;
int csmaMinFreeSamples = SIM_CSMA_MIN_FREE_SAMPLES;
int csmaRxTxDelay = SIM_CSMA_RXTX_DELAY;
int csmaAckTime = SIM_CSMA_ACK_TIME;

int sim_csma_init_high() __attribute__ ((C, spontaneous)) {
  return csmaInitHigh;
}
int sim_csma_init_low() __attribute__ ((C, spontaneous)) {
  return csmaInitLow;
}
int sim_csma_high() __attribute__ ((C, spontaneous)) {
  return csmaHigh;
}
int sim_csma_low() __attribute__ ((C, spontaneous)) {
  return csmaLow;
}
int sim_csma_symbols_per_sec() __attribute__ ((C, spontaneous)) {
  return csmaSymbolsPerSec;
}
int sim_csma_bits_per_symbol() __attribute__ ((C, spontaneous)) {
  return csmaBitsPerSymbol;
}
int sim_csma_preamble_length() __attribute__ ((C, spontaneous)) {
  return csmaPreambleLength;
}
int sim_csma_exponent_base() __attribute__ ((C, spontaneous)) {
  return csmaExponentBase;;
}
int sim_csma_max_iterations() __attribute__ ((C, spontaneous)) {
  return csmaMaxIterations;
}
int sim_csma_min_free_samples() __attribute__ ((C, spontaneous)) {
  return csmaMinFreeSamples;
}
int sim_csma_rxtx_delay() __attribute__ ((C, spontaneous)) {
  return csmaRxTxDelay;
}
int sim_csma_ack_time() __attribute__ ((C, spontaneous)) {
  return csmaAckTime;
}



void sim_csma_set_init_high(int val) __attribute__ ((C, spontaneous)) {
  csmaInitHigh = val;
}
void sim_csma_set_init_low(int val) __attribute__ ((C, spontaneous)) {
  csmaInitLow = val;
}
void sim_csma_set_high(int val) __attribute__ ((C, spontaneous)) {
  csmaHigh = val;
}
void sim_csma_set_low(int val) __attribute__ ((C, spontaneous)) {
  csmaLow = val;
}
void sim_csma_set_symbols_per_sec(int val) __attribute__ ((C, spontaneous)) {
  csmaSymbolsPerSec = val;
}
void sim_csma_set_bits_per_symbol(int val) __attribute__ ((C, spontaneous)) {
  csmaBitsPerSymbol = val;
}
void sim_csma_set_preamble_length(int val) __attribute__ ((C, spontaneous)) {
  csmaPreambleLength = val;
}
void sim_csma_set_exponent_base(int val) __attribute__ ((C, spontaneous)) {
  csmaExponentBase = val;
}
void sim_csma_set_max_iterations(int val) __attribute__ ((C, spontaneous)) {
  csmaMaxIterations = val;
}
void sim_csma_set_min_free_samples(int val) __attribute__ ((C, spontaneous)) {
  csmaMinFreeSamples = val;
}
void sim_csma_set_rxtx_delay(int val) __attribute__ ((C, spontaneous)) {
  csmaRxTxDelay = val;
}
void sim_csma_set_ack_time(int val) __attribute__ ((C, spontaneous)) {
  csmaAckTime = val;
}

