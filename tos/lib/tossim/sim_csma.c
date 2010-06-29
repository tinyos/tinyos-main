/*
 * Copyright (c) 2005 Stanford University. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 *
 * C implementation of configuration parameters for a CSMA link.
 *
 * @author Philip Levis
 * @date   Dec 10 2005
 */

// $Id: sim_csma.c,v 1.5 2010-06-29 22:07:51 scipio Exp $

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

