/*
 * Copyright (c) 2011, University of Szeged
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
 * - Neither the name of the copyright holder nor the names of
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
 *
 * Author: Zsolt Szabo
 */

module RCCalibrateP {
	provides interface RCCalibrate;
}
implementation {
	enum {
    XTAL_FREQUENCY = 32768,
    EXTERNAL_TICKS = 100,
    DEFAULT_OSCCAL_MASK = 0x00,
    DEFAULT_OSCCAL_MASK_HIGH = 0x80,
    OSCCAL_BITS = 7,
  };

  enum {
    LOOP_CYCLES = 7,
  };

  #define CALIBRATION_METHOD_SIMPLE

  unsigned char neighborsSearched;
  //! The binary search step size
  unsigned char calStep;
  //! The lowest difference between desired and measured counter value
  unsigned char bestCountDiff = 0xFF;
  //! Stores the lowest difference between desired and measured counter value for the first search
  unsigned char bestCountDiff_first;
  //! The OSCCAL value corresponding to the bestCountDiff
  unsigned char bestOSCCAL;
  //! Stores the OSCCAL value corresponding to the bestCountDiff for the first search
  unsigned char bestOSCCAL_first;
  //! The desired counter value
  unsigned int countVal;
  //! Calibration status
  unsigned int calibration;
  //! Stores the direction of the binary step (-1 or 1)
  signed char sign;

  uint32_t calibrationFrequency;


  #define DEFAULT_OSCCAL_HIGH ((1 << (OSCCAL_BITS - 1)) | DEFAULT_OSCCAL_MASK_HIGH)
  #define INITIAL_STEP         (1 << (OSCCAL_BITS - 2))
  #define DEFAULT_OSCCAL      ((1 << (OSCCAL_BITS - 1)) | DEFAULT_OSCCAL_MASK)
  
  inline void prepareCalibration(void) { calStep = INITIAL_STEP; calibration = 0; }

  #define COMPUTE_COUNT_VALUE() \
  countVal = ((EXTERNAL_TICKS*calibrationFrequency)/(XTAL_FREQUENCY*LOOP_CYCLES));
    
  // Set up timer to be ASYNCHRONOUS from the CPU clock with a second EXTERNAL 32,768kHz CRYSTAL driving it. No prescaling on asynchronous timer.
  #define SETUP_ASYNC_TIMER() \
  ASSR |= (1<<AS2); \
  TCCR2B = (1<<CS20);

  #define ABS(var) (((var) < 0) ? -(var) : (var));

  inline void NOP() { asm volatile ("nop":::"memory"); }

  void CalibrationInit(void){
    COMPUTE_COUNT_VALUE();                                        // Computes countVal for use in the calibration
    OSCCAL = DEFAULT_OSCCAL;
    NOP();

    SETUP_ASYNC_TIMER();                                          // Asynchronous timer setup
  }

  unsigned int Counter(void){
    unsigned int cnt;

    cnt = 0;                                                      // Reset counter
    TCNT2 = 0x00;                                                 // Reset async timer/counter
    while (ASSR & ((1<<OCR2AUB)|(1<<TCN2UB)|(1<<TCR2AUB))); // Wait until async timer is updated  (Async Status reg. busy flags).
    do{                                                           // cnt++: Increment counter - the add immediate to word (ADIW) takes 2 cycles of code.
      cnt++;                                                      // Devices with async TCNT in I/0 space use 1 cycle reading, 2 for devices with async TCNT in extended I/O space
    } while (TCNT2 < EXTERNAL_TICKS);                             // CPI takes 1 cycle, BRCS takes 2 cycles, resulting in: 2+1(or 2)+1+2=6(or 7) CPU cycles
    return cnt;                                                   // NB! Different compilers may give different CPU cycles!
  }  

  void CalibrateInternalRc(void){
  unsigned int count;

  #ifdef CALIBRATION_METHOD_SIMPLE                                // Simple search method
  unsigned char cycles = 0x80;

  do{
    count = Counter();
    if (count > countVal)
      OSCCAL--;                                                 // If count is more than count value corresponding to the given frequency:
    NOP();                                                      // - decrease speed
    if (count < countVal)
      OSCCAL++;
    NOP();                                                      // If count is less: - increase speed
    if (count == countVal)
      cycles=1;			
  } while(--cycles);                                            // Calibrate using 128(0x80) calibration cycles

  #else
  #endif
  }

  async command void RCCalibrate.calibrateInternalRC(uint32_t HzToCalib) {
    calibrationFrequency = HzToCalib;
    
    CalibrationInit();
    prepareCalibration();
    CalibrateInternalRc();
  }          

}
