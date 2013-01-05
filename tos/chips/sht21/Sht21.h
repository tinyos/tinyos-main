/* Copyright 2010 Unicomp Kft. All rights reserved. Released under BSD license below.


Redistribution and use in source and binary forms, with or without modification, are
permitted provided that the following conditions are met:

   1. Redistributions of source code must retain the above copyright notice, this list of
      conditions and the following disclaimer.

   2. Redistributions in binary form must reproduce the above copyright notice, this list
      of conditions and the following disclaimer in the documentation and/or other materials
      provided with the distribution.

THIS SOFTWARE IS PROVIDED BY UNICOMP KFT AND ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are those of the
authors and should not be interpreted as representing official policies, either expressed
or implied, of Unicomp Kft.
*/


/*
 * @author Gabor Salamon <gabor.salamon@unicomp.hu>
 */
#ifndef SHT21_H
#define SHT21_H

#define UQ_SHT21_RESOURCE "Sht21.Common.Resource"


enum
{
	SHT21_ADDRESS = 0x40,
	STS21_ADDRESS = 0x4A,
	SHT21_TEMP_HM = 0xE3,
	SHT21_HUMID_HM = 0xE5,
	SHT21_TEMP = 0xF3,
	SHT21_HUMID = 0xF5,
	SHT21_W_REG = 0xE6,
	SHT21_R_REG = 0xE7,
	SHT21_RESET = 0xFE
};

enum
{
	SHT21_WAIT = 90,
	SHT21_RESET_WAIT = 15,
};
#endif /* SHT21_H */
