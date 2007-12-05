/*
 * Copyright (c) 2007 Matus Harvan
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * The name of the author may not be used to endorse or promote
 *       products derived from this software without specific prior
 *       written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "Timer.h"

#define min(a,b) ( (a>b) ? b : a )
#define max(a,b) ( (a>b) ? a : b )

module CliC {
  uses {
    interface Leds;
    interface Boot;
    interface IP;
    interface UDPClient;
    interface SplitControl as IPControl;
#ifdef ENABLE_SOUNDER
    interface Mts300Sounder as Sounder;
#endif /* ENABLE_SOUNDER */
#ifdef ENABLE_TEMP_SENSOR
    interface Read<uint16_t> as TempSensorC;
#endif /* ENABLE_TEMP_SENSOR */
#ifdef ENABLE_LIGHT_SENSOR
    interface Read<uint16_t> as LightSensorC;
#endif /* ENABLE_LIGHT_SENSOR */
  }
}
implementation {
#ifndef MINIMIZE_MEMORY
    char *help_buf = "6lowpan cli supported commands:\n"
                     "\tset led {0,1,2} {on,off} -- toggle leds\n"
#ifdef ENABLE_SOUNDER
                     "\tsounder time_in_ms\n"
#endif /* ENABLE_SOUNDER */
#ifdef ENABLE_TEMP_SENSOR
                     "\tget temp\n"
#endif /* ENABLE_TEMP_SENSOR */
#ifdef ENABLE_LIGHT_SENSOR
                     "\tget light\n"
#endif /* ENABLE_LIGHT_SENSOR */
                     "\tsend small udp\n"
                     "\tsend large udp\n"
                     "\thelp\n";
    char *small_udp_buf = "\n";
    char *large_udp_buf = "\n";
    /*
    char *small_udp_buf = "----- SMALL UDP DATA BUFFER -----\n";
    char *large_udp_buf =
	    "This is a large testing string. It should undergo " \
	    "6lowpan fragmentation\n" \
            "0............................................................\n" \
            "1............................................................\n" \
            "2............................................................\n" \
            "3............................................................\n" \
            "4............................................................\n" \
            "5............................................................\n" \
            "6............................................................\n" \
            "7............................................................\n" \
            "8............................................................\n" \
            "9............................................................\n" \
            "A............................................................\n" \
            "B............................................................\n" \
            "C............................................................\n" \
            "D............................................................\n" \
            "E............................................................\n" \
            "10...........................................................\n" \
            "11...........................................................\n" \
            "12...........................................................\n" \
            "13(shorter)\n" \
	    "---- END OF THE LARGE UDP DATA ----\n";
    */
#if defined(ENABLE_TEMP_SENSOR) || defined(ENABLE_LIGHT_SENSOR)
    char sensor_buf[15];
    bool sensor_buf_busy = FALSE;
    ip6_addr_t sensor_addr;
    uint16_t sensor_port;
#endif /* ENABLE_TEMP_SENSOR | ENABLE_LIGHT_SENSOR */
#endif /* MINIMIZE_MEMORY */

    event void Boot.booted() {
      /* set an IP address */
      ip6_addr_t addr = {{0x20, 0x01,
			 0x06, 0x38,
			 0x07, 0x09,
			 0x12, 0x34,
			 0x00, 0x00,
			 0x00, 0x00,
			 0x00, 0x00,
			 0x00, 0x00
      }};
      //call IP.setAddress(&addr);
        call IP.setAddressAutoconf(&addr);

	call IPControl.start();
    }
    
    event void IPControl.startDone(error_t err) {

	call UDPClient.listen(1234);
    }
    event void IPControl.stopDone(error_t err) {}

    event void UDPClient.receive(const ip6_addr_t *addr, const uint16_t port,
				 uint8_t *buf, uint16_t len )
    {
#ifndef MINIMIZE_MEMORY
	if ( strncmp(buf, "set ", min(len, 4)) == 0 && len>0) {
	    buf += 4;
	    len -= 4;
	    if ( strncmp(buf, "led ", min(len, 4)) == 0 && len>0) {
		buf += 4;
		len -= 4;

		if ( strncmp(buf, "0 ", min(len, 2)) == 0 && len>0) {
		    buf += 2;
		    len -= 2;
		    if ( strncmp(buf, "on", min(len, 2)) == 0 && len>0) {
			call Leds.led0On();
		    } else if (strncmp(buf, "off", min(len, 3)) == 0 && len>0){
			call Leds.led0Off();
		    }
		} else if ( strncmp(buf, "1 ", min(len, 2)) == 0 && len>0) {
		    buf += 2;
		    len -= 2;
		    if ( strncmp(buf, "on", min(len, 2)) == 0 && len>0) {
			call Leds.led1On();
		    } else if (strncmp(buf, "off", min(len, 3)) == 0 && len>0){
			call Leds.led1Off();
		    }
		} else if ( strncmp(buf, "2 ", min(len, 2)) == 0 && len>0) {
		    buf += 2;
		    len -= 2;
		    if ( strncmp(buf, "on", min(len, 2)) == 0 && len>0) {
			call Leds.led2On();
		    } else if (strncmp(buf, "off", min(len, 3)) == 0 && len>0){
			call Leds.led2Off();
		    }
		} 
	    }
#ifdef ENABLE_SOUNDER
	} else if ( strncmp(buf, "sounder ", min(len, 8)) == 0
		    && len>0) {
	    buf += 8;
	    len -= 8;
	    call Sounder.beep(atoi(buf));
#endif /* ENABLE_SOUNDER */

#ifdef ENABLE_TEMP_SENSOR
	} else if ( strncmp(buf, "get temp", min(len, 8)) == 0
		    && len>0) {
	    memcpy(&sensor_addr, addr, sizeof(*addr));
	    sensor_port = port;
	    //call UDPClient.sendTo(addr, port, "reading temp...\n", 16);
	    call TempSensorC.read();
#endif /* ENABLE_TEMP_SENSOR */

#ifdef ENABLE_LIGHT_SENSOR
	} else if ( strncmp(buf, "get light", min(len, 8)) == 0
		    && len>0) {
	    memcpy(&sensor_addr, addr, sizeof(*addr));
	    sensor_port = port;
	    //call UDPClient.sendTo(addr, port, "reading light...\n", 17);
	    call LightSensorC.read();
#endif /* ENABLE_LIGHT_SENSOR */

	} else if (strncmp(buf, "send large udp", min(len, 14)) == 0
		   && len>0) {
	    call UDPClient.sendTo(addr, port,
				  large_udp_buf, strlen(large_udp_buf));
	} else if (strncmp(buf, "send small udp", min(len, 14)) == 0
		   && len>0) {
	    call UDPClient.sendTo(addr, port,
				  small_udp_buf, strlen(small_udp_buf));
	} else if (strncmp(buf, "help", min(len, 14)) == 0
		   && len>0) {
	    call UDPClient.sendTo(addr, port,
				  help_buf, strlen(help_buf));
	} else {
	    call UDPClient.sendTo(addr, port,
				  help_buf, strlen(help_buf));
	}
#endif /* MINIMIZE_MEMORY */
    }
    
    event void UDPClient.sendDone(error_t result, void* buf)
    {
#if defined(ENABLE_TEMP_SENSOR) || defined(ENABLE_LIGHT_SENSOR)
	if (buf == sensor_buf) {
	    sensor_buf_busy = FALSE;
	}
#endif /* ENABLE_TEMP_SENSOR | ENABLE_LIGHT_SENSOR */
    }

#ifdef ENABLE_TEMP_SENSOR
  event void TempSensorC.readDone(error_t result, uint16_t data) {
      if (sensor_buf_busy == FALSE) {
	  sensor_buf_busy = TRUE;
	  if (result == SUCCESS) {
	      snprintf(sensor_buf, sizeof(sensor_buf), "temp: %d\n", data);
	  } else {
	      snprintf(sensor_buf, sizeof(sensor_buf), "temp: -\n");
	  }
	  call UDPClient.sendTo(&sensor_addr, sensor_port,
				sensor_buf, strlen(sensor_buf));
      } else {
	  call UDPClient.sendTo(&sensor_addr, sensor_port,
				"busy\n", 5);
      }
  }
#endif /* ENABLE_TEMP_SENSOR */

#ifdef ENABLE_LIGHT_SENSOR
  event void LightSensorC.readDone(error_t result, uint16_t data) {
      if (sensor_buf_busy == FALSE) {
	  sensor_buf_busy = TRUE;
	  if (result == SUCCESS) {
	      snprintf(sensor_buf, sizeof(sensor_buf), "light: %d\n", data);
	  } else {
	      snprintf(sensor_buf, sizeof(sensor_buf), "light: -\n");
	  }
	  call UDPClient.sendTo(&sensor_addr, sensor_port,
				sensor_buf, strlen(sensor_buf));
      } else {
	  call UDPClient.sendTo(&sensor_addr, sensor_port,
				"busy\n", 5);
      }
  }
#endif /* ENABLE_LIGHT_SENSOR */
}
