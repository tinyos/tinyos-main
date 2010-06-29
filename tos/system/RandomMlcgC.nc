/*
 * Copyright (c) 2002-2005 The Regents of the University  of California.  
 * All rights reserved.
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
 * - Neither the name of the University of California nor the names of
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
/** This code is a fast implementation of the Park-Miller Minimal Standard 
 *  Generator for pseudo-random numbers.  It uses the 32 bit multiplicative 
 *  linear congruential generator, 
 *
 *		S' = (A x S) mod (2^31 - 1) 
 *
 *  for A = 16807.
 *
 *
 * @author Barbara Hohlt 
 * @date   March 1 2005
 */

module RandomMlcgC @safe() {
  provides interface Init;
  provides interface ParameterInit<uint16_t> as SeedInit;
  provides interface Random;
}
implementation
{
    uint32_t seed ;

  /* Initialize the seed from the ID of the node */
  command error_t Init.init() {
    atomic  seed = (uint32_t)(TOS_NODE_ID + 1);
    
    return SUCCESS;
  }

  /* Initialize with 16-bit seed */ 
  command error_t SeedInit.init(uint16_t s) {
    atomic  seed = (uint32_t)(s + 1);
    
    return SUCCESS;
  }

  /* Return the next 32 bit random number */
  async command uint32_t Random.rand32() {
    uint32_t mlcg,p,q;
    uint64_t tmpseed;
    atomic
      {
	tmpseed =  (uint64_t)33614U * (uint64_t)seed;
	q = tmpseed; 	/* low */
	q = q >> 1;
	p = tmpseed >> 32 ;		/* hi */
	mlcg = p + q;
        if (mlcg & 0x80000000) { 
	  mlcg = mlcg & 0x7FFFFFFF;
	  mlcg++;
	}
	seed = mlcg;
      }
    return mlcg; 
  }

  /* Return low 16 bits of next 32 bit random number */
  async command uint16_t Random.rand16() {
    return (uint16_t)call Random.rand32();
  }

#if 0
 /* Return high 16 bits of 32 bit number */
 inline uint16_t getHigh16(uint32_t num) {
    return num >> 16;
 }
#endif
}
