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
 * Configuration parameters for a CSMA link.
 *
 * @author Philip Levis
 * @date   Dec 10 2005
 */

#include <mac.h>
#include <sim_csma.h>

MAC::MAC() {}
MAC::~MAC() {}

int MAC::initHigh() {return sim_csma_init_high();}
int MAC::initLow() {return sim_csma_init_low();}
int MAC::high() {return sim_csma_high();}
int MAC::low() {return sim_csma_low();}
int MAC::symbolsPerSec() {return sim_csma_symbols_per_sec();}
int MAC::bitsPerSymbol() {return sim_csma_bits_per_symbol();}
int MAC::preambleLength() {return sim_csma_preamble_length();}
int MAC::exponentBase() {return sim_csma_exponent_base();}
int MAC::maxIterations() {return sim_csma_max_iterations();}
int MAC::minFreeSamples() {return sim_csma_min_free_samples();}
int MAC::rxtxDelay() {return sim_csma_rxtx_delay();}
int MAC::ackTime() {return sim_csma_ack_time();}

void MAC::setInitHigh(int val) {sim_csma_set_init_high(val);}
void MAC::setInitLow(int val) {sim_csma_set_init_low(val);}
void MAC::setHigh(int val) {sim_csma_set_high(val);}
void MAC::setLow(int val) {sim_csma_set_low(val);}
void MAC::setSymbolsPerSec(int val) {sim_csma_set_symbols_per_sec(val);}
void MAC::setBitsBerSymbol(int val) {sim_csma_set_bits_per_symbol(val);}
void MAC::setPreambleLength(int val) {sim_csma_set_preamble_length(val);}
void MAC::setExponentBase(int val) {sim_csma_set_exponent_base(val);}
void MAC::setMaxIterations(int val) {sim_csma_set_max_iterations(val);}
void MAC::setMinFreeSamples(int val) {sim_csma_set_min_free_samples(val);}
void MAC::setRxtxDelay(int val) {sim_csma_set_rxtx_delay(val);}
void MAC::setAckTime(int val) {sim_csma_set_ack_time(val);}

