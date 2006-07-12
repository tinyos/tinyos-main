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
 * C++ implementation of the default TOSSIM CSMA model.
 *
 * @author Philip Levis
 * @date   Dec 10 2005
 */

#include <csma.h>

Csma::Csma() {}
Csma::~Csma() {}

int Csma::initHigh() {return sim_csma_init_high();}
int Csma::initLow() {return sim_csma_init_low();}
int Csma::high() {return sim_csma_high();}
int Csma::low() {return sim_csma_low();}
int Csma::symbolsPerSec() {return sim_csma_symbols_per_sec();}
int Csma::bitsPerSymbol() {return sim_csma_bits_per_symbol();}
int Csma::preambleLength() {return sim_csma_preamble_length();}
int Csma::exponentBase() {return sim_csma_exponent_base();}
int Csma::maxIterations() {return sim_csma_max_iterations();}
int Csma::minFreeSamples() {return sim_csma_min_free_samples();}
int Csma::rxtxDelay() {return sim_csma_rxtx_delay();}
int Csma::ackTime() {return sim_csma_ack_time();}

void Csma::setInitHigh(int val) {sim_csma_set_init_high(val);}
void Csma::setInitLow(int val) {sim_csma_set_init_low(val);}
void Csma::setHigh(int val) {sim_csma_set_high(val);}
void Csma::setLow(int val) {sim_csma_set_low(val);}
void Csma::setSymbolsPerSec(int val) {sim_csma_set_symbols_per_sec(val);}
void Csma::setBitsBerSymbol(int val) {sim_csma_set_bits_per_symbol(val);}
void Csma::setPreambleLength(int val) {sim_csma_set_preamble_length(val);}
void Csma::setExponentBase(int val) {sim_csma_set_exponent_base(val);}
void Csma::setMaxIterations(int val) {sim_csma_set_max_iterations(val);}
void Csma::setMinFreeSamples(int val) {sim_csma_set_min_free_samples(val);}
void Csma::setRxtxDelay(int val) {sim_csma_set_rxtx_delay(val);}
void Csma::setAckTime(int val); {sim_csma_set_ack_time(val);}

#endif
