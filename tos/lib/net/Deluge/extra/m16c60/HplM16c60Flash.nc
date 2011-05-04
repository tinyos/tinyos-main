/*
 * Copyright (c) 2011 Lulea University of Technology
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
 * - Neither the name of the copyright holders nor the names of
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
 * Interface to access the program flash of a M16c/60 mcu.
 * 
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */
interface HplM16c60Flash
{
  /**
   * Erases a block in the program flash.
   *
   * @param block The block that should be erased.
   * @return SUCCESS if the erase succeeded without errors else FAIL.
   */
  command error_t erase(unsigned char block);
  
  /**
   * Writes bytes into the program flash.
   *
   * @param flash_addr The program flash address where the write should begin. This MUST be an EVEN address.
   * @param buffer_addr The bytes that should be written to the address.
   * @param bytes The number of bytes that should be written. This MUST be an EVEN number.
   * @return FAIL if the flash control reported an error. EINVAL if the parameters that where passed contained an error
   * 		 if everything went ok it returns SUCCESS.
   */
  command error_t write(unsigned long flash_addr_in,
                        unsigned int* buffer_addr,
                        unsigned int bytes);
                              
  /**
   * Reads the byte at am address using a LDE instruction.
   *
   * @param address The address that a byte should be read from.
   * @return Byte read.
   */
  command uint8_t read(unsigned long flash_addr_in);
}
