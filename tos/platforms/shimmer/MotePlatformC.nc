/*
 * Copyright (c) 2006, Intel Corporation
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
 * @author Steven Ayer
 * @date June 2006
 */

module MotePlatformC {
  provides interface Init;
}
implementation {
  command error_t Init.init() {
    
    //LEDS
    TOSH_MAKE_RED_LED_OUTPUT();
    TOSH_MAKE_YELLOW_LED_OUTPUT();
    TOSH_MAKE_ORANGE_LED_OUTPUT();
    TOSH_MAKE_GREEN_LED_OUTPUT();
    TOSH_SEL_RED_LED_IOFUNC();
    TOSH_SEL_YELLOW_LED_IOFUNC();
    TOSH_SEL_ORANGE_LED_IOFUNC();
    TOSH_SEL_GREEN_LED_IOFUNC();

    TOSH_CLR_RED_LED_PIN();
    TOSH_CLR_YELLOW_LED_PIN();
    TOSH_CLR_ORANGE_LED_PIN();
    TOSH_CLR_GREEN_LED_PIN();

    //RADIO PINS
    //CC2420 pins
    TOSH_MAKE_RADIO_CSN_OUTPUT();
    TOSH_SEL_RADIO_CSN_IOFUNC();
    TOSH_SET_RADIO_CSN_PIN();

    TOSH_MAKE_CSN_OUTPUT();
    TOSH_SEL_CSN_IOFUNC();
    TOSH_SET_CSN_PIN();

    // should be reset_n
    TOSH_MAKE_RADIO_RESET_OUTPUT();
    TOSH_SEL_RADIO_RESET_IOFUNC();
    TOSH_CLR_RADIO_RESET_PIN();

    TOSH_MAKE_RADIO_1V8_EN_OUTPUT();
    TOSH_SEL_RADIO_1V8_EN_IOFUNC();
    TOSH_CLR_RADIO_1V8_EN_PIN();

    TOSH_MAKE_RADIO_CCA_INPUT();
    TOSH_MAKE_RADIO_FIFO_INPUT();
    TOSH_MAKE_RADIO_FIFOP_INPUT();
    TOSH_MAKE_RADIO_SFD_INPUT();
    TOSH_MAKE_RADIO_TIMED_SFD_INPUT();
    TOSH_SEL_RADIO_CCA_IOFUNC();
    TOSH_SEL_RADIO_FIFO_IOFUNC();
    TOSH_SEL_RADIO_FIFOP_IOFUNC();
    TOSH_SEL_RADIO_SFD_IOFUNC();
    TOSH_SEL_RADIO_TIMED_SFD_IOFUNC();

    TOSH_MAKE_ONEWIRE_PWR_OUTPUT();
    TOSH_SET_ONEWIRE_PWR_PIN();

    TOSH_SEL_SD_CS_N_IOFUNC();
    TOSH_MAKE_SD_CS_N_OUTPUT();
    TOSH_SET_SD_CS_N_PIN();

    // BT PINS
    TOSH_MAKE_BT_RESET_OUTPUT();  
    TOSH_SEL_BT_RESET_IOFUNC();    
    TOSH_CLR_BT_RESET_PIN();   // mitsumi module disabled by clr

    TOSH_MAKE_BT_RTS_INPUT();      
    TOSH_SEL_BT_RTS_IOFUNC();

    TOSH_MAKE_BT_PIO_INPUT();
    TOSH_SEL_BT_PIO_IOFUNC();

    TOSH_MAKE_BT_CTS_OUTPUT();
    TOSH_SEL_BT_CTS_IOFUNC();

    TOSH_MAKE_BT_TXD_OUTPUT();
    TOSH_SEL_BT_TXD_MODFUNC();

    TOSH_MAKE_BT_RXD_INPUT();
    TOSH_SEL_BT_RXD_MODFUNC();

    // BSL Prog Pins tristate em

    TOSH_MAKE_PROG_IN_OUTPUT();
    TOSH_MAKE_PROG_OUT_OUTPUT();
    TOSH_SET_PROG_OUT_PIN();    // some expansion boards have enable low
    TOSH_SEL_PROG_IN_IOFUNC();
    TOSH_SEL_PROG_OUT_IOFUNC();

    // USART lines, attached to a pullup
    TOSH_SEL_UCLK0_IOFUNC();
    TOSH_MAKE_UCLK0_OUTPUT();
    TOSH_SET_UCLK0_PIN();
    TOSH_SEL_UCLK1_IOFUNC();
    TOSH_MAKE_UCLK1_OUTPUT();
    TOSH_SET_UCLK1_PIN();

    TOSH_SEL_SIMO0_IOFUNC();
    TOSH_MAKE_SIMO0_OUTPUT();
    TOSH_SET_SIMO0_PIN();
    TOSH_SEL_SOMI0_IOFUNC();
    TOSH_MAKE_SOMI0_INPUT();

    TOSH_SEL_SIMO1_IOFUNC();
    TOSH_MAKE_SIMO1_OUTPUT();
    TOSH_SET_SIMO1_PIN();
    TOSH_SEL_SOMI1_IOFUNC();
    TOSH_MAKE_SOMI1_INPUT();

    // ADC lines
    TOSH_MAKE_ADC_0_OUTPUT();
    TOSH_MAKE_ADC_1_OUTPUT();
    TOSH_MAKE_ADC_2_OUTPUT();
    TOSH_MAKE_ADC_6_OUTPUT();
    TOSH_MAKE_ADC_7_OUTPUT();

    TOSH_SEL_ADC_0_IOFUNC();
    TOSH_SEL_ADC_1_IOFUNC();
    TOSH_SEL_ADC_2_IOFUNC();
    TOSH_SEL_ADC_6_IOFUNC();
    TOSH_SEL_ADC_7_IOFUNC();
  
    TOSH_MAKE_ADC_ACCELZ_INPUT();
    TOSH_MAKE_ADC_ACCELY_INPUT();
    TOSH_MAKE_ADC_ACCELX_INPUT();
    TOSH_SEL_ADC_ACCELZ_MODFUNC();
    TOSH_SEL_ADC_ACCELY_MODFUNC();
    TOSH_SEL_ADC_ACCELX_MODFUNC();
  
    TOSH_SEL_ROSC_IOFUNC();
    TOSH_MAKE_ROSC_INPUT();

    // DAC lines
    // Default is not to use DAC mode.  Please define pin usage if you want to use them
    
    // UART pins
    // These declarations are to allow the UART module to work since it's using the names.
    // The UART module will set them to the right direction when initialized

    // ftdi/gio pins.  Unused for now so we do not set directionality or function


    // 1-wire function
    TOSH_MAKE_ONEWIRE_PWR_OUTPUT();
    TOSH_SEL_ONEWIRE_PWR_IOFUNC();
    TOSH_MAKE_ONEWIRE_INPUT();
    TOSH_SEL_ONEWIRE_IOFUNC();

    // Accelerometer pin definitions
    TOSH_SEL_ACCEL_SEL0_IOFUNC();
    TOSH_SEL_ACCEL_SEL1_IOFUNC();
    TOSH_SEL_ACCEL_SLEEP_N_IOFUNC();
  
    TOSH_MAKE_ACCEL_SEL0_OUTPUT();
    TOSH_MAKE_ACCEL_SEL1_OUTPUT();
    TOSH_MAKE_ACCEL_SLEEP_N_OUTPUT();

    /*
     * unless the accel_sel0 pin is cleared, 
     * a severe quiescent power hit occurs on the msp430
     * we go from 3.7 ua to 65.1 ua when asleep!
     */
    TOSH_CLR_ACCEL_SEL0_PIN();
    TOSH_CLR_ACCEL_SEL1_PIN();
    TOSH_CLR_ACCEL_SLEEP_N_PIN();


    // idle expansion header pins
    TOSH_MAKE_SER0_CTS_OUTPUT();
    TOSH_SEL_SER0_CTS_IOFUNC();
    TOSH_MAKE_SER0_RTS_OUTPUT();
    TOSH_SEL_SER0_RTS_IOFUNC();
    TOSH_MAKE_GIO0_INPUT();
    TOSH_SEL_GIO0_IOFUNC();
    TOSH_MAKE_GIO1_OUTPUT();
    TOSH_SEL_GIO1_IOFUNC();
    TOSH_MAKE_UTXD0_OUTPUT();
    TOSH_SEL_UTXD0_IOFUNC();
    TOSH_MAKE_URXD0_OUTPUT();
    TOSH_SEL_URXD0_IOFUNC();
    TOSH_MAKE_RADIO_VREF_OUTPUT();
    TOSH_SEL_RADIO_VREF_IOFUNC();

    return SUCCESS;
  }
}
