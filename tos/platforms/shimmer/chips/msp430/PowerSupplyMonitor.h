/*
 * Copyright (c) 2007, Intel Corporation
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 * Redistributions of source code must retain the above copyright notice, 
 * this list of conditions and the following disclaimer. 
 *
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution. 
 *
 * Neither the name of the Intel Corporation nor the names of its contributors
 * may be used to endorse or promote products derived from this software 
 * without specific prior written permission. 
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
 * POSSIBILITY OF SUCH DAMAGE.
 *
 * @author  Steve Ayer
 * @date    March, 2007
 *
 * enum to set svs thresholds, presumably more meaningful than "vld_n"?
 */

// as in 1.9v, 2.1v, etc.
enum {
  OFF,
  ONE_9V =  VLD0,    
  TWO_1V =  VLD1,
  TWO_2V =  VLD1 | VLD0,
  TWO_3V =  VLD2,
  TWO_4V =  VLD2 | VLD0,
  TWO_5V =  VLD2 | VLD1,
  TWO_65V = VLD2 | VLD1 | VLD0,
  TWO_8V =  VLD3,
  TWO_9V =  VLD3 | VLD0,
  THREE_05V = VLD3 | VLD1,
  THREE_2V =  VLD3 | VLD1 | VLD0,
  THREE_35V = VLD3 | VLD2,
  THREE_5V =  VLD3 | VLD2 | VLD0,
  THREE_7V =  VLD3 | VLD2 | VLD1,
  EXTERNAL =  VLD3 | VLD2 | VLD1 | VLD0
};
