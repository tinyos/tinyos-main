/*
 * Copyright (c) 2004, Technische Universitaet Berlin
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
 * - Neither the name of the Technische Universitaet Berlin nor the names
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
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.4 $
 * $Date: 2006-12-12 18:23:13 $
 * @author: Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */

#include "tda5250Const.h"
/**
 * This interface provides commands and events for configureing the radio modes.
 *
 * @author Kevin Klues
 */
interface HplTda5250Config {
   /**
    * Resets all Radio Registers to default values.
    * The default values can be found in tda5250RegDefaults.h
   */
   async command void reset();

   /**
   * Set the data slicer to use the RC integrator. 
   * The data slicer is an analog-to-digital converter for the radio data.
   * When using RC integrator the mean value of the analog data is used 
   * to convert the analog data to a Bit.
   */
   async command void UseRCIntegrator();
   
   /**
   * Set the data slicer to use the Peak Detector. 
   * The data slicer is an analog-to-digital converter for the radio data.
   * When using peak detector the peak value of the analog data is used 
   * to convert the analog data to a Bit.
   */
   async command void UsePeakDetector();
   
   /**
   * Powers the radio down.
   */
   async command void PowerDown();
   
   /**
   * Powers the radio up.
   */
   async command void PowerUp();
   
   /** 
   * Switch radio to test operation.
   * FIXME: Whatever this means...
   */
   async command void RunInTestMode();
   
   /**
   * Switches the radio to normal operation.
   */
   async command void RunInNormalMode();
   
   /**
   * Control the radio Tx and Rx mode externally.
   */
   async command void ControlRxTxExternally();
   
   /** 
   * Control the radio Tx and Rx mode internally.
   */
   async command void ControlRxTxInternally();
   
   /** 
   * Use FSK modulation.
   *
   * @param pos_shift Capacitor value for positive shift.
   * @param neg_shift Capacitor value for negative shift.
   */
   async command void UseFSK(tda5250_cap_vals_t pos_shift, tda5250_cap_vals_t neg_shift);
   
   /** 
   * Use ASK mosulation.
   *
   * @param pos_shift Capacitor value for positive shift. (FIXME: makes sense?)
   */
   async command void UseASK(tda5250_cap_vals_t pos_shift);
   
   /**
   * Disables internal clock during power down.
   */
   async command void SetClockOffDuringPowerDown();
   
   /**
   * Enables internal clock during power down.
   */
   async command void SetClockOnDuringPowerDown();
   
   /**
   * Enables inverting the radio data.
   */
   async command void InvertData();
   
   /**
   * Disables inverting radio data.
   */
   async command void DontInvertData();
   
   /** 
   * Use the RSSI data valid detection.
   * For the data valid detection 3 thresholds must be defined. 
   * The data is only considered valid if the RSSI is greater than RSSI threshold 
   * and the data rate is between the lower and upper data rate threshold.
   *
   * @param value The RSSI threshold for valid data.
   * @param lower_bound Lower data rate threshold.
   * @param upper_bound Upper data rate threshold.
   */
   async command void UseRSSIDataValidDetection(uint8_t value, uint16_t lower_bound, uint16_t upper_bound);
   
   /** 
    * Use the Vcc data valid detection.
    * For the data valid detection 3 thresholds must be defined. 
    * The data is only considered valid if the voltage is greater than voltage threshold 
    * and the data rate is between the lower and upper data rate threshold.
    *
    * @param value The voltage threshold for valid data.
    * @param lower_bound Lower data rate threshold.
    * @param upper_bound Upper data rate threshold.
   */
   async command void UseVCCDataValidDetection(uint8_t value, uint16_t lower_bound, uint16_t upper_bound);
   
   /**
   * Use the data valid detection.
   * This means that the receiving data is checked either by RSSI data valid detection or
   * by Vcc data valid detection if it is actual data and no noise.
   */
   async command void UseDataValidDetection();
   
   /** Do not use data valid detection. 
   * This means that it is assumed that the receiving data is
   * always valid data.
   * It is absolutely necessary to
   * set the RSSI-ADC (and the Window counter) into continuous mode.
   */
   async command void UseDataAlwaysValid();
   
   /**
   * Sets the ADC to continious mode.
   * Analog sampling data is taken continously.
   */
   async command void ADCContinuousMode();
   
   /**
   * Sets the ADC to one shot mode.
   * The sampling data is taken in one shot.
   */
   async command void ADCOneShotMode();
     
   /**
   * Sets the data calid detection in continous mode.
   */
   async command void DataValidContinuousMode();
   
   /**
   * Sets the data calid detection in one shot mode.
   */
   async command void DataValidOneShotMode();
   
   /**
   * Sets the low noise amplifier to high gain
   */
   async command void HighLNAGain();
   
   /**
   * Sets the low noise amplifier to low gain
   */
   async command void LowLNAGain();
   
   /** 
   * Enables the receiver when in TIMER_MODE or SELF_POLLING_MODE.
   */
   async command void EnableReceiverInTimedModes();
   
   /** 
   * Disables the receiver when in TIMER_MODE or SELF_POLLING_MODE.
   */
   async command void DisableReceiverInTimedModes();
   
   /**
   * Use high transmit power.
   */
   async command void UseHighTxPower();
   
   /**
   * Use low transmit power.
   */
   async command void UseLowTxPower();
   
   /**
   * Tune the nominal frequency with a Bipolar FET.
   *
   * @param ramp_time Ramp time.
   * @param cap_val Capacitor value.
   */
   async command void TuneNomFreqWithBipolarFET(tda5250_bipolar_fet_ramp_times_t ramp_time, tda5250_cap_vals_t cap_val);
   
   /**
   * Tune the nominal frequency with a FET
   *
   * @param cap_val Capacitor value.
   */
   async command void TuneNomFreqWithFET(tda5250_cap_vals_t cap_val);

   /**
   * Set the mode of the radio to SlaveMode.
   */
   async command void SetSlaveMode();
     
   /**
   * Set the mode of the radio to TimerMode.
   * 
   * @param on_time The time (ms) the radio is on.
   * @param off_time The time (ms) the radio is off.
   */
   async command void SetTimerMode(float on_time, float off_time);
      
   /**
    * Resets the timers set in SetTimerMode().
    */
   async command void ResetTimerMode();
      
   /**
   * Set the mode of the radio to SetSelfPollingMode.
   *
   * @param on_time The time (ms) the radio is on.
   * @param off_time The time (ms) the radio is off.
   */
   async command void SetSelfPollingMode(float on_time, float off_time);
      
   /**
    * Reset the timers set in SetSelfPollingMode.
    */
   async command void ResetSelfPollingMode();

   /**
    * Set the contents of the LPF register with the Low pass filter 
    * 
    * @param data_cutoff LowPassFilter characteristics. For recognized values see tda5250Const.h
    */
   async command void SetLowPassFilter(tda5250_data_cutoff_freqs_t data_cutoff);
   
   /**
   * Set the contents of the LPF register with the IQ filter value.
   * 
   * @param iq_cutoff IQ filter characteristics. For recognized values see tda5250Const.h
   */
   async command void SetIQFilter(tda5250_iq_cutoff_freqs_t iq_cutoff);

   /**
    *  Set the on time time of the radio.
    *  This only makes sense when radio is in TIMER or SELF_POLLING Mode.
    * 
    *  @param time The time (ms) the radio is on.
   */
   async command void SetOnTime_ms(float time);
      
   /**
   *  Set the off time time of the radio.
   *  This only makes sense when radio is in TIMER or SELF_POLLING Mode.
   * 
   *  @param time The time (ms) the radio is off.
   */
   async command void SetOffTime_ms(float time);

   
   
   /**
   * Initialzes the CLK_DIV so that SetRadioClock(tda5250_clock_out_freqs_t freq)
   * can be used.
   */
   async command void UseSetClock();
   
   /**
   * Sets the CLK_DIV to specified output. UseSetClock() must be called before!
   * Available frequencies given in TDA5250ClockFreq_t struct in tda5250Const.h.
   *
   * @param freq The new clock frequency (see tda5250.h).
   */
   async command void SetRadioClock(tda5250_clock_out_freqs_t freq);
   
   /**
   * Sets the CLK_DIV to 18Mhz output.
   */
   async command void Use18MHzClock();
   
   /**
   * Sets the CLK_DIV to 32Khz output.
   */
   async command void Use32KHzClock();
   
   /**
   * Sets the CLK_DIV to use window count as output.
   */
   async command void UseWindowCountAsClock();
   


   /**
   * Set the value on the attached Potentiometer
   * for the RF Power setting.
   *
   * @param RF Power.
   */
   async command void SetRFPower(uint8_t value);

   /**
   * Sets the RSSI threshold for internal evaluation.
   *
   * @param RSSI threshold value.
   */
   async command void SetRSSIThreshold(uint8_t value);
   
   /** 
   * Sets the threshold values for internal evaluation.
   * (FIXME: what threshold is set with this?)
   *
   * @param value Threshold value.
   */
   async command void SetVCCOver5Threshold(uint8_t value);
   
   /** 
   * Sets the lower data rate threshold for data valid detection.
   *
   * @param Lower data rate threshold value.
   */
   async command void SetLowerDataRateThreshold(uint16_t value);
   
   /** 
   * Sets the upper data rate threshold for data valid detection.
   *
   * @param Upper data rate threshold value.
   */
   async command void SetUpperDataRateThreshold(uint16_t value);

   /**
   * Gets the currnet RSSI value.
   *
   * @return Current RSSI.
   */
   async command uint8_t GetRSSIValue();
   
   /**
   * Gets the current status of the ADC select feedback Bit. 
   * The ADC select feedback Bit is "0" if the ADC is connected to 
   * a resistor network dividing the Vcc voltage by 5.
   * The ADC select feedback Bit is "1" if the ADC is connected to
   * the RSSI voltage.
   *
   * @return "0" if ADC connected to Vcc/5.
   *         "1" if ADC connected to RSSI voltage.
   */
   async command uint8_t GetADCSelectFeedbackBit();
   
   /**
   * Gets the current status of the ADC Power down feedback Bit.
   * The ADC Power down feedback Bit is "0" if ADC power is up.
   * It is "1" if ADC power is down.
   *
   * @return "0" if ADC power is up
   *         "1" otherwise.
   */
   async command uint8_t GetADCPowerDownFeedbackBit();
   
   /**
   * Checks if the data rate is less than the lower threshold set by
   * SetLowerDataRateThreshold(uint16_t value).
   *
   * @return TRUE if data rate is less than lower threshold
   *         FALSE otherwise.
   */
   async command bool IsDataRateLessThanLowerThreshold();
   
   /**
   * Checks if the data rate is between the lower threshold set by
   * SetLowerDataRateThreshold(uint16_t value) and upper threshold set by
   * SetUpperDataRateThreshold(uint16_t value).
   *
   * @return TRUE if data rate is between the lower and upper threshold
   *         FALSE otherwise.
   */
   async command bool IsDataRateBetweenThresholds();
   
   /**
   * Checks if the data rate is less than the upper threshold set by
   * SetUpperDataRateThreshold(uint16_t value).
   *
   * @return TRUE if data rate is less than upper threshold
   *         FALSE otherwise.
   */
   async command bool IsDataRateLessThanUpperThreshold();
   
   /**
   * Checks if the data rate is less than half of the lower threshold set by
   * SetLowerDataRateThreshold(uint16_t value).
   *
   * @return TRUE if data rate is less than half of the lower threshold
   *         FALSE otherwise.
   */
   async command bool IsDataRateLessThanHalfOfLowerThreshold();
   
   /**
   * Checks if the data rate is between the halves of the lower threshold set by
   * SetLowerDataRateThreshold(uint16_t value) and the upper threshold set by
   * SetUpperDataRateThreshold(uint16_t value).
   *
   * @return TRUE if the data rate is between the halves of the lower and upper threshold
   *         FALSE otherwise.
   */
   async command bool IsDataRateBetweenHalvesOfThresholds();
   
   /**
   * Checks if the data rate is half of the upper threshold set by
   * SetUpperDataRateThreshold(uint16_t value).
   *
   * @return TRUE if data rate is less than half of the upper threshold
   *         FALSE otherwise.
   */
   async command bool IsDataRateLessThanHalfOfUpperThreshold();
   
   /**
   * Checks if the current RSSI equals the threshold set 
   * with SetRSSIThreshold(uint8_t value).
   *
   * @return TRUE if RSSI equals the threshold value
   *         FALSE otherwise.
   */
   async command bool IsRSSIEqualToThreshold();
   
   /**
   * Checks if the current RSSI is graeter than the threshold set 
   * with SetRSSIThreshold(uint8_t value).
   *
   * @return TRUE if RSSI greater than threshold value
   *         FALSE otherwise.
   */
   async command bool IsRSSIGreaterThanThreshold();

   /**
   * Checks if the Tx Rx and Sleep radiomodes can be set via pin.
   * This only concerns SetTxMode(), SetRxMode() and SetSleepMode().
   *
   * @return TRUE if radiomodes can be set via pin
   *         FALSE otherwise.
   */
   async command bool IsTxRxPinControlled();
   
   /**
   * Switches the radio to TxMode when in SLAVE_MODE
   */
   async command void SetTxMode();
   
   /**
   * Switches the radio to RxMode when in SLAVE_MODE
   */
   async command void SetRxMode();
   
   /**
   * Switches the radio to SleepMode when in SLAVE_MODE
   */
   async command void SetSleepMode();

   /**
   * Notification of interrupt when in
   * TimerMode or SelfPollingMode.
   */
   async event void PWDDDInterrupt();
}

