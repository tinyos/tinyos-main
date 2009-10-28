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
 * Implementation of the Control Interfaces for the M16c/62p mcu.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */


#include "M16c62pControl.h"

module M16c62pControlP
{
  provides interface M16c62pControl;
  provides interface StopModeControl[uint8_t client];
  provides interface SystemClockControl[uint8_t client];

  uses interface M16c62pControlPlatform as PlatformCtrl;
}
implementation
{
  M16c62pSystemClock default_system_clock = M16C62P_MAIN_CLOCK_DIV_0; // Default system clock speed
  M16c62pSystemClock system_clock = M16C62P_DONT_CARE; 
  uint8_t client_system_clock[uniqueCount(UQ_M16C62P_SYSTEM_CLOCK_CONTROL)];
  uint8_t num_system_clock_clients = uniqueCount(UQ_M16C62P_SYSTEM_CLOCK_CONTROL);
  
  // Take +1 incase of rest in the division
  uint8_t client_allow_stop_mode[(uniqueCount(UQ_M16C62P_STOP_MODE_CONTROL)/8) + 1];
  uint8_t num_allow_stop_mode_clients = uniqueCount(UQ_M16C62P_STOP_MODE_CONTROL);
  bool update_sleep_mode = false;
  bool allow_stop_mode = true; // Stop mode enabled/disabled, Default: Enabled.
  
  void PLLOn()
  {
    uint8_t tmp;
    uint32_t i;

    CM0.BYTE = 0x08; // Main clock + Sub clock.
    CM1.BYTE = 0x20; //Clear previous cpu speed setting.
    PM2.BYTE = 0x00; // PLL > 16MHz (2 waits).
    tmp = 0x90 + PLL_MULTIPLIER;
    PLC0.BYTE = tmp; // PLL ON.
    // Wait for PLL to become stable (50 ms).
    // TODO (henrik) Make this more efficient when time allows it.For example
    //               use timers or busy waiting.
    //               Tried busy waiting but tosboot started to include alot of
    //               things that it shouldn't which lead to compile errors.
    for (i = 0; i < 50000 * MAIN_CRYSTAL_SPEED; ++i)
      asm("nop");
    CM1.BYTE = 0x22; // PLL as system clock.
    call PlatformCtrl.PLLOn();
  }

  void PLLOff()
  {
    uint8_t tmp;
    CLR_BIT(CM1.BYTE, 1); // Main clock
    tmp = 0x10 + PLL_MULTIPLIER;
    PLC0.BYTE = tmp; // Turn off PLL clock
    call PlatformCtrl.PLLOff();
  }
  
  error_t setSystemClock(M16c62pSystemClock set_clock)
  {
    M16c62pSystemClock clock = set_clock;
    atomic
    {      
      if (clock == M16C62P_DONT_CARE)
      {
        clock = default_system_clock;
      }
      
      PRCR.BYTE = BIT1 | BIT0; // Turn off protection for cpu & clock register.
      
      if (system_clock == M16C62P_PLL_CLOCK)
      {
        PLLOff();
      }

      // Set correct system clock speed.
      if (clock == M16C62P_MAIN_CLOCK_DIV_8)
      {
        SET_BIT(CM0.BYTE, 6);
      }
      else if (clock >= M16C62P_MAIN_CLOCK_DIV_0 &&
               clock <= M16C62P_MAIN_CLOCK_DIV_16)
      { // Main clock divided by 0, 2 ,4 or 16
        CLR_BIT(CM0.BYTE, 6); // Remove division by 8
        CLR_FLAG(CM1.BYTE, (0x3 << 6)); // Clear previous cpu speed setting
        SET_FLAG(CM1.BYTE, ((clock >> 2) << 6)); // New cpu speed
      }
      else if (clock == M16C62P_SUB_CLOCK)
      {
        SET_BIT(CM0.BYTE, 4); // Sub clock on.
        SET_BIT(CM0.BYTE, 7); // Sub clock as CPU clock  
      }
      else if (clock == M16C62P_PLL_CLOCK)
      {
        PLLOn();
      }
      // TODO(Henrik) Maybe need to wait for a while to make sure that the
      //              crystals are stable?
      CLR_BIT(CM1.BYTE, 5); // Low drive on Xin-Xout.
      CLR_BIT(CM0.BYTE, 3); // Low drive on XCin-XCout.
      PRCR.BYTE = 0;           // Turn on protection on all registers.
      atomic system_clock = set_clock;
      return SUCCESS;
    }
  }

  error_t updateSystemClock()
  {
    M16c62pSystemClock clock = M16C62P_DONT_CARE;
    uint8_t i;

    atomic
    {
      for (i = 0; i < num_system_clock_clients; ++i)
      {
        if (clock < client_system_clock[i])
        {
          clock = client_system_clock[i];
        }
      }
      
      if (clock == system_clock)
      {
        return SUCCESS;
      }
      
      return setSystemClock(clock); 
    }
  }

  void initPin(volatile uint8_t *port, volatile uint8_t *port_d, uint8_t pin, uint16_t state)
  {
    uint8_t inactive = (state >> (pin*2)) & 0x3;
    // Turn off protection of PD9
    PRCR.BYTE = BIT2;
    switch (inactive)
    {
      case M16C_PIN_INACTIVE_DONT_CARE:
        break;
      case M16C_PIN_INACTIVE_OUTPUT_LOW:
        SET_BIT((*port_d), pin);
        CLR_BIT((*port), pin);
        break;
      case M16C_PIN_INACTIVE_OUTPUT_HIGH:
        SET_BIT((*port_d), pin);
        SET_BIT((*port), pin);
        break;
      case M16C_PIN_INACTIVE_INPUT:
        CLR_BIT((*port_d), pin);
        CLR_BIT((*port), pin);
        break;
    }
    PRCR.BYTE = 0;
  }
  
  void initPort(volatile uint8_t *port, volatile uint8_t *port_d, uint16_t state)
  {
    initPin(port, port_d, 0, state);
    initPin(port, port_d, 1, state);
    initPin(port, port_d, 2, state);
    initPin(port, port_d, 3, state);
    initPin(port, port_d, 4, state);
    initPin(port, port_d, 5, state);
    initPin(port, port_d, 6, state);
    initPin(port, port_d, 7, state);
  }
  
  void initPins()
  {
    initPort(&P0.BYTE, &PD0.BYTE, PORT_P0_INACTIVE_STATE);
    initPort(&P1.BYTE, &PD1.BYTE, PORT_P1_INACTIVE_STATE);
    initPort(&P2.BYTE, &PD2.BYTE, PORT_P2_INACTIVE_STATE);
    initPort(&P3.BYTE, &PD3.BYTE, PORT_P3_INACTIVE_STATE);
    initPort(&P4.BYTE, &PD4.BYTE, PORT_P4_INACTIVE_STATE);
    initPort(&P5.BYTE, &PD5.BYTE, PORT_P5_INACTIVE_STATE);
    initPort(&P6.BYTE, &PD6.BYTE, PORT_P6_INACTIVE_STATE);
    initPort(&P7.BYTE, &PD7.BYTE, PORT_P7_INACTIVE_STATE);
    initPort(&P8.BYTE, &PD8.BYTE, PORT_P8_INACTIVE_STATE);
    initPort(&P9.BYTE, &PD9.BYTE, PORT_P9_INACTIVE_STATE);
    initPort(&P10.BYTE, &PD10.BYTE, PORT_P_10_INACTIVE_STATE);
  }
  
  command error_t M16c62pControl.init()
  {
    uint8_t i;
    uint8_t tmp;
    initPins();
    PRCR.BYTE = BIT1 | BIT0; // Turn off protection for cpu & clock register.

    PM0.BYTE = BIT7;         // Single Chip mode. No BCLK output.
    PM1.BYTE = BIT3;         // Expand internal memory, no global wait state.
    PCLKR.BIT.PCLK0 = 1;     // Set Timer A and B clock bit to F1
    PCLKR.BIT.PCLK1 = 1;     // Set Timer A and B clock bit to F1
    
    tmp = 0x10 + PLL_MULTIPLIER; // Prepare PLL multiplier
    PLC0.BYTE = tmp; // Set PLL multiplier
    
    PRCR.BYTE = 0;
 
    // Initialize the clock and stop mode control arrays.
    for (i = 0; i < num_system_clock_clients; ++i)
    {
      client_system_clock[i] = M16C62P_DONT_CARE;
    }
    for (i = 0; i < (num_allow_stop_mode_clients/8) + 1; ++i)
    {
      client_allow_stop_mode[i] = 0xFF;
    }
    return setSystemClock(M16C62P_DONT_CARE);
  }

  command error_t M16c62pControl.defaultSystemClock(
      M16c62pSystemClock def)
  {
    if (def == M16C62P_DONT_CARE)
    {
      return FAIL;
    }
    if (def == default_system_clock || system_clock != M16C62P_DONT_CARE)
    {
      default_system_clock = def;
      return SUCCESS;
    }
    default_system_clock = def;
    return setSystemClock(M16C62P_DONT_CARE);
  }

  void updateSleepMode()
  {
    uint8_t i;
    for (i = 0; i < (num_allow_stop_mode_clients/8) + 1; ++i)
    {
      if (client_allow_stop_mode[i] != 0xFF)
      {
        allow_stop_mode = false;
        return;
      }
    }
    allow_stop_mode = true;
  }

  void waitMode()
  {
    __nesc_enable_interrupt();
    asm ("wait");
    asm volatile ("" : : : "memory");
    __nesc_disable_interrupt();
  }

  void stopMode()
  {
    uint8_t cm0_tmp, cm1_tmp;
    __nesc_enable_interrupt();
    PRCR.BYTE = 1; // Turn off protection of system clock control registers
    cm0_tmp = CM0.BYTE;
    cm1_tmp = CM1.BYTE;
    CM0.BYTE = 0b00001000;
    asm("bset 0,0x0007"); // Enter stop mode
    asm("jmp.b MAIN_A");
    asm("MAIN_A:");
    asm("nop");
    asm("nop");
    asm("nop");
    asm("nop");
    PRCR.BYTE = 0; // Turn off protection of system clock control registers
    asm volatile ("" : : : "memory");
    __nesc_disable_interrupt();
    CM0.BYTE = cm0_tmp;
    CM1.BYTE = cm1_tmp;
    PRCR.BIT.PRC0 = 0; // Turn on protection of system clock control registers
  }

  async command void M16c62pControl.sleep()
  {
    atomic if (update_sleep_mode)
    {
      updateSleepMode();
    }
    if (allow_stop_mode && system_clock != M16C62P_PLL_CLOCK)
    {
      stopMode();
    }
    else
    {
      waitMode();
    }
  }

  async command void StopModeControl.allowStopMode[uint8_t client](bool allow)
  {
    atomic
    {
      WRITE_BIT(client_allow_stop_mode[client >> 3], client % 8, allow);
      if (allow != allow_stop_mode)
      {
        update_sleep_mode = true;
      }
    }
  }

  command error_t SystemClockControl.minSpeed[uint8_t client](
      M16c62pSystemClock speed)
  {
    atomic client_system_clock[client] = speed;
    atomic if (system_clock < speed)
    {
      return updateSystemClock();
    }
    return SUCCESS;
  }
}
