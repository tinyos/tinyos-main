/*
 * Copyright (c) 2009 Communication Group and Eislab at
 * Lulea University of Technology
 *
 * Contact: Laurynas Riliskis, LTU
 * Mail: laurynas.riliskis@ltu.se
 * All rights reserved.
 *
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
 * - Neither the name of Communication Group at Lulea University of Technology
 *   nor the names of its contributors may be used to endorse or promote
 *    products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */
  
/**
 * Generic pin access for pins on the P9 port. The PD9 register
 * is locked by the PRC2 bit in the PRCR register so it needs
 * to be unlocked before each access.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */

generic module HplM16c60GeneralIOPinPRC2P()
{
  provides interface GeneralIO as IO;
 
  uses interface GeneralIO as Wrap;
}
implementation
{

  inline async command bool IO.get()        { return call Wrap.get(); }
  inline async command void IO.set()        { call Wrap.set(); }
  inline async command void IO.clr()        { call Wrap.clr(); }
  inline async command void IO.toggle()     { call Wrap.toggle(); }
    
  inline async command void IO.makeInput() 
  {
    atomic
    {
  	  PRCR.BYTE = BIT2;
  	  call Wrap.makeInput();
    }
  }
  
  inline async command bool IO.isInput()    { return call Wrap.isInput(); }
  inline async command void IO.makeOutput()
  {
    atomic
    {
      PRCR.BYTE = BIT2;
  	  call Wrap.makeOutput();
    }
  }
  
  inline async command bool IO.isOutput()   { return call Wrap.isOutput(); }
}

