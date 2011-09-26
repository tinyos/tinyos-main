/*
 * Copyright (c) 2009 DEXMA SENSORS SL
 * Copyright (c) 2011 ZOLERTIA LABS
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 *
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

/*
 * Implementation of ADXL345 accelerometer, as a part of Zolertia Z1 mote
 *
 * Credits goes to DEXMA SENSORS SL
 * @author: Xavier Orduna <xorduna@dexmatech.com>
 * @author: Jordi Soucheiron <jsoucheiron@dexmatech.com>
 * @author: Antonio Linan <alinan@zolertia.com>
 */

interface ADXL345Control
{
    command error_t setRange(uint8_t range, uint8_t resolution);
    event void setRangeDone(error_t error);

    command error_t setInterrups(uint8_t interrupt_vector);
    event void setInterruptsDone(error_t error);

    command error_t setIntMap(uint8_t int_map_vector);
    event void setIntMapDone(error_t error);

    command error_t setRegister(uint8_t reg, uint8_t value);
    event void setRegisterDone(error_t error);

    command error_t setDuration(uint8_t duration);
    event void setDurationDone(error_t error);

    command error_t setLatent(uint8_t latent);
    event void setLatentDone(error_t error);

    command error_t setWindow(uint8_t window);
    event void setWindowDone(error_t error);

    command error_t setReadAddress(uint8_t address);
    event void setReadAddressDone(error_t error);

}
