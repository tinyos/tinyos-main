/*
 * Copyright (c) 2004, Technische Universitat Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitat Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * - Revision -------------------------------------------------------------
 * $Revision: 1.4 $
 * $Date: 2006-12-12 18:23:13 $
 * ========================================================================
 */

 /**
 * tda5250Const Header File
 * Defines constants and macros for use with the TDA5250 Radio
 *
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
 */

#ifndef TDA5250CONST_H
#define TDA5250CONST_H

// List of valid output frequencies for clock
typedef enum {
   CLOCK_OUT_FREQ_NINE_MHZ                        = 0x00,
   CLOCK_OUT_FREQ_FOUR_POINT_FIVE_MHZ             = 0x01,
   CLOCK_OUT_FREQ_THREE_MHZ                       = 0x02,
   CLOCK_OUT_FREQ_TWO_POINT_TWO_FIVE_MHZ          = 0x03,
   CLOCK_OUT_FREQ_ONE_POINT_EIGHT_MHZ             = 0x04,
   CLOCK_OUT_FREQ_ONE_POINT_FIVE_MHZ              = 0x05,
   CLOCK_OUT_FREQ_ONE_POINT_TWO_EIGHT_MHZ         = 0x06,
   CLOCK_OUT_FREQ_ONE_POINT_ONE_TWO_FIVE_MHZ      = 0x07,
   CLOCK_OUT_FREQ_ONE_MHZ                         = 0x08,
   CLOCK_OUT_FREQ_POINT_NINE_MHZ                  = 0x09,
   CLOCK_OUT_FREQ_POINT_EIGHT_TWO_MHZ             = 0x0A,
   CLOCK_OUT_FREQ_POINT_SEVEN_FIVE_MHZ            = 0x0B,
   CLOCK_OUT_FREQ_POINT_SIX_NINE_MHZ              = 0x0C,
   CLOCK_OUT_FREQ_POINT_SIX_FOUR_MHZ              = 0x0D,
   CLOCK_OUT_FREQ_POINT_SIX_MHZ                   = 0x0E,
   CLOCK_OUT_FREQ_POINT_FIVE_SIX_MHZ              = 0x0F,
   CLOCK_OUT_FREQ_THIRTY_TWO_KHZ                  = 0x80,
   CLOCK_OUT_FREQ_WINDOW_COUNT_COMPLETE           = 0xC0
} tda5250_clock_out_freqs_t;

//List of valid cutoff frequencies for the IQ Filter
typedef enum {
   DATA_CUTOFF_FREQ_FIVE_KHZ                        = 0x00,
   DATA_CUTOFF_FREQ_SEVEN_KHZ                       = 0x01,
   DATA_CUTOFF_FREQ_NINE_KHZ                        = 0x02,
   DATA_CUTOFF_FREQ_ELEVEN_KHZ                      = 0x03,
   DATA_CUTOFF_FREQ_FOURTEEN_KHZ                    = 0x04,
   DATA_CUTOFF_FREQ_EIGHTEEN_KHZ                    = 0x05,
   DATA_CUTOFF_FREQ_TWENTY_THREE_KHZ                = 0x06,
   DATA_CUTOFF_FREQ_TWENTY_EIGHT_KHZ                = 0x07,
   DATA_CUTOFF_FREQ_THIRTY_TWO_KHZ                  = 0x08,
   DATA_CUTOFF_FREQ_THIRTY_NINE_KHZ                 = 0x09,
   DATA_CUTOFF_FREQ_FOURTY_NINE_KHZ                 = 0x0A,
   DATA_CUTOFF_FREQ_FIFTY_FIVE_KHZ                  = 0x0B,
   DATA_CUTOFF_FREQ_SIXTY_FOUR_KHZ                  = 0x0C,
   DATA_CUTOFF_FREQ_SEVENTY_THREE_KHZ               = 0x0D,
   DATA_CUTOFF_FREQ_EIGHTY_SIX_KHZ                  = 0x0E,
   DATA_CUTOFF_FREQ_ONE_HUNDRED_TWO_KHZ             = 0x0F
} tda5250_data_cutoff_freqs_t;

//List of valid cutoff frequencies for the Lowpass
  //data filter
typedef enum {
   IQ_CUTOFF_FREQ_THREE_HUNDRED_FIFTY_KHZ         = 0x01,
   IQ_CUTOFF_FREQ_TWO_HUNDRED_FIFTY_KHZ           = 0x02,
   IQ_CUTOFF_FREQ_TWO_HUNDRED_KHZ                 = 0x03,
   IQ_CUTOFF_FREQ_ONE_HUNDRED_FIFTY_KHZ           = 0x04,
   IQ_CUTOFF_FREQ_ONE_HUNDRED_KHZ                 = 0x05,
   IQ_CUTOFF_FREQ_FIFTY_KHZ                       = 0x06
} tda5250_iq_cutoff_freqs_t;

//List of valid capacitor values for tuning the nominal
  //frequency setting
typedef enum {
   CAP_VAL_ZERO_F                          = 0x00,
   CAP_VAL_TWO_HUNDRED_FIFTY_FF            = 0x01,
   CAP_VAL_FIVE_HUNDRED_FIFTY_FF           = 0x02,
   CAP_VAL_SEVEN_HUNDRED_FIFTY_FF          = 0x03,
   CAP_VAL_ONE_PF                          = 0x04,
   CAP_VAL_ONE_POINT_TWO_FIVE_PF           = 0x05,
   CAP_VAL_ONE_POINT_FIVE_PF               = 0x06,
   CAP_VAL_ONE_POINT_SEVEN_FIVE_PF         = 0x07,
   CAP_VAL_TWO_PF                          = 0x08,
   CAP_VAL_TWO_POINT_TWO_FIVE_PF           = 0x09,
   CAP_VAL_TWO_POINT_FIVE_PF               = 0x0A,
   CAP_VAL_TWO_POINT_SEVEN_FIVE_PF         = 0x0B,
   CAP_VAL_THREE_PF                        = 0x0C,
   CAP_VAL_THREE_POINT_TWO_FIVE_PF         = 0x0D,
   CAP_VAL_THREE_POINT_FIVE_PF             = 0x0E,
   CAP_VAL_THREE_POINT_SEVEN_FIVE_PF       = 0x0F,
   CAP_VAL_FOUR_PF                         = 0x10,
   CAP_VAL_FOUR_POINT_TWO_FIVE_PF          = 0x11,
   CAP_VAL_FOUR_POINT_FIVE_PF              = 0x12,
   CAP_VAL_FOUR_POINT_SEVEN_FIVE_PF        = 0x13,
   CAP_VAL_FIVE_PF                         = 0x14,
   CAP_VAL_FIVE_POINT_TWO_FIVE_PF          = 0x15,
   CAP_VAL_FIVE_POINT_FIVE_PF              = 0x16,
   CAP_VAL_FIVE_POINT_SEVEN_FIVE_PF        = 0x17,
   CAP_VAL_SIX_PF                          = 0x18,
   CAP_VAL_SIX_POINT_TWO_FIVE_PF           = 0x19,
   CAP_VAL_SIX_POINT_FIVE_PF               = 0x1A,
   CAP_VAL_SIX_POINT_SEVEN_FIVE_PF         = 0x1B,
   CAP_VAL_SEVEN_PF                        = 0x1C,
   CAP_VAL_SEVEN_POINT_TWO_FIVE_PF         = 0x1D,
   CAP_VAL_SEVEN_POINT_FIVE_PF             = 0x1E,
   CAP_VAL_SEVEN_POINT_SEVEN_FIVE_PF       = 0x1F,
   CAP_VAL_EIGHT_PF                        = 0x10,
   CAP_VAL_EIGHT_POINT_TWO_FIVE_PF         = 0x11,
   CAP_VAL_EIGHT_POINT_FIVE_PF             = 0x12,
   CAP_VAL_EIGHT_POINT_SEVEN_FIVE_PF       = 0x13,
   CAP_VAL_NINE_PF                         = 0x14,
   CAP_VAL_NINE_POINT_TWO_FIVE_PF          = 0x15,
   CAP_VAL_NINE_POINT_FIVE_PF              = 0x16,
   CAP_VAL_NINE_POINT_SEVEN_FIVE_PF        = 0x17,
   CAP_VAL_TEN_PF                          = 0x18,
   CAP_VAL_TEN_POINT_TWO_FIVE_PF           = 0x19,
   CAP_VAL_TEN_POINT_FIVE_PF               = 0x1A,
   CAP_VAL_TEN_POINT_SEVEN_FIVE_PF         = 0x1B,
   CAP_VAL_ELEVEN_PF                       = 0x1C,
   CAP_VAL_ELEVEN_POINT_TWO_FIVE_PF        = 0x1D,
   CAP_VAL_ELEVEN_POINT_FIVE_PF            = 0x1E,
   CAP_VAL_ELEVEN_POINT_SEVEN_FIVE_PF      = 0x1F,
   CAP_VAL_TWELVE_PF                       = 0x10,
   CAP_VAL_TWELVE_POINT_TWO_FIVE_PF        = 0x11,
   CAP_VAL_TWELVE_POINT_FIVE_PF            = 0x12,
   CAP_VAL_TWELVE_POINT_SEVEN_FIVE_PF      = 0x13,
   CAP_VAL_THIRTEEN_PF                     = 0x14,
   CAP_VAL_THIRTEEN_POINT_TWO_FIVE_PF      = 0x15,
   CAP_VAL_THIRTEEN_POINT_FIVE_PF          = 0x16,
   CAP_VAL_THIRTEEN_POINT_SEVEN_FIVE_PF    = 0x17,
   CAP_VAL_FOURTEEN_PF                     = 0x18,
   CAP_VAL_FOURTEEN_POINT_TWO_FIVE_PF      = 0x19,
   CAP_VAL_FOURTEEN_POINT_FIVE_PF          = 0x1A,
   CAP_VAL_FOURTEEN_POINT_SEVEN_FIVE_PF    = 0x1B,
   CAP_VAL_FIFTEEN_PF                      = 0x1C,
   CAP_VAL_FIFTEEN_POINT_TWO_FIVE_PF       = 0x1D,
   CAP_VAL_FIFTEEN_POINT_FIVE_PF           = 0x1E,
   CAP_VAL_FIFTEEN_POINT_SEVEN_FIVE_PF     = 0x1F
} tda5250_cap_vals_t;

//List of valid times for Bipolar Ramp
typedef enum {
   BIPOLAR_FET_RAMP_TIME_LESS_THAN_TWO_MS                = 0x01,
   BIPOLAR_FET_RAMP_TIME_FOUR_MS                         = 0x03,
   BIPOLAR_FET_RAMP_TIME_EIGHT_MS                        = 0x05,
   BIPOLAR_FET_RAMP_TIME_TWELVE_MS                       = 0x07
} tda5250_bipolar_fet_ramp_times_t;

#define TDA5250_RECEIVE_FREQUENCY               868.3      // kHz
#define TDA5250_OSCILLATOR_FREQUENCY            ((3.0/4.0) * TDA5250_RECEIVE_FREQUENCY) // kHz
#define TDA5250_INTERMEDIATE_FREQUENCY          ((3.0) * TDA5250_RECEIVE_FREQUENCY) // kHz
#define TDA5250_INTERNAL_OSC_FREQUENCY          32.768 //kHz
#define TDA5250_CLOCK_OUT_BASE_FREQUENCY        18089.6 //kHz
#define TDA5250_CONSTANT_FOR_FREQ_TO_TH_VALUE   2261  //khz of integer for 18089.6/2/4
#define TDA5250_CONVERT_TIME(time)         ((uint16_t)(0xFFFF - ((time*TDA5250_INTERNAL_OSC_FREQUENCY))))
#define TDA5250_CONVERT_FREQ_TO_TH_VALUE(freq, clock_freq) \
           ((TDA5250_CONSTANT_FOR_FREQ_TO_TH_VALUE/(clock_freq*freq))*1000)

#define TDA5250_SYSTEM_SETUP_TIME            (12000/TDA5250_INTERNAL_OSC_FREQUENCY) //12000us
#define TDA5250_RECEIVER_SETUP_TIME           (2860/TDA5250_INTERNAL_OSC_FREQUENCY) // 2860us
#define TDA5250_DATA_DETECTION_SETUP_TIME     (3380/TDA5250_INTERNAL_OSC_FREQUENCY) // 3380us
#define TDA5250_RSSI_STABLE_TIME              (3380/TDA5250_INTERNAL_OSC_FREQUENCY) // 3380us
#define TDA5250_CLOCK_OUT_SETUP_TIME           (500/TDA5250_INTERNAL_OSC_FREQUENCY) //  500us
#define TDA5250_TRANSMITTER_SETUP_TIME        (1430/TDA5250_INTERNAL_OSC_FREQUENCY) // 1430us
#define TDA5250_XTAL_STARTUP_TIME              (500/TDA5250_INTERNAL_OSC_FREQUENCY) //  500us

// Subaddresses of data registers write
#define TDA5250_REG_ADDR_CONFIG            0x00
#define TDA5250_REG_ADDR_FSK               0x01
#define TDA5250_REG_ADDR_XTAL_TUNING       0x02
#define TDA5250_REG_ADDR_LPF               0x03
#define TDA5250_REG_ADDR_ON_TIME           0x04
#define TDA5250_REG_ADDR_OFF_TIME          0x05
#define TDA5250_REG_ADDR_COUNT_TH1         0x06
#define TDA5250_REG_ADDR_COUNT_TH2         0x07
#define TDA5250_REG_ADDR_RSSI_TH3          0x08
#define TDA5250_REG_ADDR_CLK_DIV           0x0D
#define TDA5250_REG_ADDR_XTAL_CONFIG       0x0E
#define TDA5250_REG_ADDR_BLOCK_PD          0x0F

// Subaddresses of data registers read
#define TDA5250_REG_ADDR_STATUS            0x80
#define TDA5250_REG_ADDR_ADC               0x81

// Mask Values for write registers (16 or 8 bit)
/************* Apply these masks by & with original */
#define MASK_CONFIG_SLICER_RC_INTEGRATOR       0x7FFF
#define MASK_CONFIG_ALL_PD_NORMAL              0xBFFF
#define MASK_CONFIG_TESTMODE_NORMAL            0xDFFF
#define MASK_CONFIG_CONTROL_TXRX_EXTERNAL      0xEFFF
#define MASK_CONFIG_ASK_NFSK_FSK               0xF7FF
#define MASK_CONFIG_RX_NTX_TX                  0xFBFF
#define MASK_CONFIG_CLK_EN_OFF                 0xFDFF
#define MASK_CONFIG_RX_DATA_INV_NO             0xFEFF
#define MASK_CONFIG_D_OUT_IFVALID              0xFF7F
#define MASK_CONFIG_ADC_MODE_ONESHOT           0xFFBF
#define MASK_CONFIG_F_COUNT_MODE_ONESHOT       0xFFDF
#define MASK_CONFIG_LNA_GAIN_LOW               0xFFEF
#define MASK_CONFIG_EN_RX_DISABLE              0xFFF7
#define MASK_CONFIG_MODE_2_SLAVE               0xFFFB
#define MASK_CONFIG_MODE_1_SLAVE_TIMER         0xFFFD
#define MASK_CONFIG_PA_PWR_LOWTX               0xFFFE
/************* Apply these masks by | with original */
#define MASK_CONFIG_SLICER_PEAK_DETECTOR       0x8000
#define MASK_CONFIG_ALL_PD_POWER_DOWN          0x4000
#define MASK_CONFIG_TESTMODE_TESTMODE          0x2000
#define MASK_CONFIG_CONTROL_TXRX_REGISTER      0x1000
#define MASK_CONFIG_ASK_NFSK_ASK               0x0800
#define MASK_CONFIG_RX_NTX_RX                  0x0400
#define MASK_CONFIG_CLK_EN_ON                  0x0200
#define MASK_CONFIG_RX_DATA_INV_YES            0x0100
#define MASK_CONFIG_D_OUT_ALWAYS               0x0080
#define MASK_CONFIG_ADC_MODE_CONT              0x0040
#define MASK_CONFIG_F_COUNT_MODE_CONT          0x0020
#define MASK_CONFIG_LNA_GAIN_HIGH              0x0010
#define MASK_CONFIG_EN_RX_ENABLE               0x0008
#define MASK_CONFIG_MODE_2_TIMER               0x0004
#define MASK_CONFIG_MODE_1_SELF_POLLING        0x0002
#define MASK_CONFIG_PA_PWR_HIGHTX              0x0001

// Mask Values for write registers (16 or 8 bit)
/************* Apply these masks by & with original */
#define CONFIG_SLICER_RC_INTEGRATOR(config)       (config & 0x7FFF)
#define CONFIG_ALL_PD_NORMAL(config)              (config & 0xBFFF)
#define CONFIG_TESTMODE_NORMAL(config)            (config & 0xDFFF)
#define CONFIG_CONTROL_TXRX_EXTERNAL(config)      (config & 0xEFFF)
#define CONFIG_ASK_NFSK_FSK(config)               (config & 0xF7FF)
#define CONFIG_RX_NTX_TX(config)                  (config & 0xFBFF)
#define CONFIG_CLK_EN_OFF(config)                 (config & 0xFDFF)
#define CONFIG_RX_DATA_INV_NO(config)             (config & 0xFEFF)
#define CONFIG_D_OUT_IFVALID(config)              (config & 0xFF7F)
#define CONFIG_ADC_MODE_ONESHOT(config)           (config & 0xFFBF)
#define CONFIG_F_COUNT_MODE_ONESHOT(config)       (config & 0xFFDF)
#define CONFIG_LNA_GAIN_LOW(config)               (config & 0xFFEF)
#define CONFIG_EN_RX_DISABLE(config)              (config & 0xFFF7)
#define CONFIG_MODE_2_SLAVE(config)               (config & 0xFFFB)
#define CONFIG_MODE_1_SLAVE_OR_TIMER(config)      (config & 0xFFFD)
#define CONFIG_PA_PWR_LOWTX(config)               (config & 0xFFFE)
#define XTAL_CONFIG_FET(xtal)                     (xtal & 0xFE)
#define XTAL_CONFIG_FSK_RAMP0_FALSE(xtal)         (xtal & 0xFB)
#define XTAL_CONFIG_FSK_RAMP1_FALSE(xtal)         (xtal & 0xFD)
/************* Apply these masks by | with original */
#define CONFIG_SLICER_PEAK_DETECTOR(config)       (config | 0x8000)
#define CONFIG_ALL_PD_POWER_DOWN(config)          (config | 0x4000)
#define CONFIG_TESTMODE_TESTMODE(config)          (config | 0x2000)
#define CONFIG_CONTROL_TXRX_REGISTER(config)      (config | 0x1000)
#define CONFIG_ASK_NFSK_ASK(config)               (config | 0x0800)
#define CONFIG_RX_NTX_RX(config)                  (config | 0x0400)
#define CONFIG_CLK_EN_ON(config)                  (config | 0x0200)
#define CONFIG_RX_DATA_INV_YES(config)            (config | 0x0100)
#define CONFIG_D_OUT_ALWAYS(config)               (config | 0x0080)
#define CONFIG_ADC_MODE_CONT(config)              (config | 0x0040)
#define CONFIG_F_COUNT_MODE_CONT(config)          (config | 0x0020)
#define CONFIG_LNA_GAIN_HIGH(config)              (config | 0x0010)
#define CONFIG_EN_RX_ENABLE(config)               (config | 0x0008)
#define CONFIG_MODE_2_TIMER(config)               (config | 0x0004)
#define CONFIG_MODE_1_SELF_POLLING(config)        (config | 0x0002)
#define CONFIG_PA_PWR_HIGHTX(config)              (config | 0x0001)
#define XTAL_CONFIG_BIPOLAR(xtal)                 (xtal | 0x01)
#define XTAL_CONFIG_FSK_RAMP0_TRUE(xtal)          (xtal | 0x04)
#define XTAL_CONFIG_FSK_RAMP1_TRUE(xtal)          (xtal | 0x02)

#endif //TDA5250CONST_H
