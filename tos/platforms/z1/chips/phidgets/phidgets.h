/*
 * Copyright (c) 2014 ZOLERTIA LABS
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
 * Header for basic analog driver to read data from a Phidget sensor
 * http://www.phidgets.com
 *
 * @author: Antonio Linan <alinan@zolertia.com>
 */

#ifndef PHIDGETS_H
#define PHIDGETS_H

  // If using a different external power source supply other than the USB, 
  // change it here
  enum {
    EXTERNAL_VREF          = 5000,
    INTERNAL_VREF          = 3300,
    EXTERNAL_VREF_OFFSET   = -28,   // Measure, compensates vref, cable quality and length, etc
    EXTERNAL_VREF_CROSSVAL = 3000,  // Internal voltage divider has 2/3 relationship
    EXTERNAL_VREF_HALF = EXTERNAL_VREF/2,
    INTERNAL_VREF_OFFSET   = -138,  // Actual +/-3VDC supplied to Z1
  };

  enum {
    NO_PHIDGET         = 0,  // No sensor selected (default)
    PHIDGET_RAW,             // Raw voltage reading
    PHIDGET_ROTATION,        // http://www.phidgets.com/products.php?product_id=1109
    PHIDGET_TOUCH,           // http://www.phidgets.com/products.php?product_id=1129
    PHIDGET_FLEXIFORCE,      // http://www.phidgets.com/products.php?product_id=1120
    PHIDGET_MAGNETIC,        // http://www.phidgets.com/products.php?product_id=1108
    PHIDGET_SHARP_DISTANCE_3520,  // http://www.phidgets.com/products.php?product_id=3520
    PHIDGET_SHARP_DISTANCE_3522,  // http://www.phidgets.com/products.php?product_id=3522
    PHIDGET_CURRENT_ACDC_30A,     // http://www.phidgets.com/products.php?product_id=1122
    PHIDGET_VOLT_30VDC,      // http://www.phidgets.com/products.php?product_id=1135
    PHIDGET_PH_3550,         // http://www.phidgets.com/products.php?product_id=1135 (pH)
    PHIDGET_ORP_3550,        // http://www.phidgets.com/products.php?product_id=1135 (ORP)
    PHIDGET_MAX,

  } phidget_sensors_t;

  char* phidgetFromVal(error_t a){
    switch(a){
      case NO_PHIDGET:
        return "NONE";
      case PHIDGET_RAW:
        return "RAW READINGS";
      case PHIDGET_ROTATION:
        return "PHIDGET ROTATION";
      case PHIDGET_TOUCH:
        return "PHIDGET TOUCH";
      case PHIDGET_FLEXIFORCE:
        return "PHIDGET FLEXIFORCE";
      case PHIDGET_MAGNETIC:
        return "PHIDGET MAGNETIC";
      case PHIDGET_SHARP_DISTANCE_3520:
        return "PHIDGET SHARP DISTANCE 3520";
      case PHIDGET_SHARP_DISTANCE_3522:
        return "PHIDGET SHARP DISTANCE 3522";
      case PHIDGET_CURRENT_ACDC_30A:
        return "PHIDGET CURRENT ACDC 30A";
      case PHIDGET_PH_3550:
        return "PHIDGET PH 3550";
      case PHIDGET_ORP_3550:
        return "PHIDGET ORP 3550";
      case PHIDGET_VOLT_30VDC:
        return "PHIDGET VOLT 30VDC";
      default:
        return "UNKNOWN";
    }
  }

#endif
