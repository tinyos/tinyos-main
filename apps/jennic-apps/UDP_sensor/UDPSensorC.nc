  /*
   * Copyright (c) 2015, Technische Universitaet Berlin
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
   * @author Jasper Buesch <buesch@tkn.tu-berlin.de>
   */


#include <lib6lowpan/ip.h>
#include "waveform.h"
#include <IeeeEui64.h>
#include "printf.h"

module UDPSensorC {
  uses {
    interface Boot;
    interface Leds;
    interface SplitControl as RadioControl;
    interface UDP as ServerInfo;
    interface UDP as SensorData;
    interface Timer<TMilli> as SensorTimer;
    interface TknTschEvents;
    interface LocalIeeeEui64;
  }
} implementation {

  #define SERVER_INFO_PORT 8085
  #define SENSOR_DATA_PORT 8086

  #define CLOCK_SECOND 1024
  #define INTERVAL 10

  #define TSCH_DEFAULT_TIMESLOT_LENGTH 10000


  //#define TSCH_HOPPING_SEQUENCE_8_8 (uint8_t[]){17, 23, 15, 25, 19, 11, 13, 21 }

  char m_sensorString[100];
  struct sockaddr_in6 m_serverAddr;
  bool m_serverPresent = FALSE;
  uint32_t m_latestASN;
  uint8_t m_selected_waveform;
    ieee_eui64_t m_nodeEUI;

  typedef enum {
    WAVEFORM_SIN = 0,
    WAVEFORM_TRIANGLE = 1,
    WAVEFORM_POS_SAWTOOTH = 2,
    WAVEFORM_NEG_SAWTOOTH = 3,
    NUMBER_OF_WAVEFORMS = 4
  } waveform_t;

  typedef struct {
    const int8 * table;
    char * str;
  } wave_t;

  static const wave_t waveform_table[] = {  {sin_table,           "SINE"},            /* WAVEFORM_SIN */
                                          {triangle_table,      "TRIANGLE"},        /* WAVEFORM_TRIANGLE */
                                          {pos_sawtooth_table,  "POS-SAWTOOTH"},    /* WAVEFORM_POS_SAWTOOTH */
                                          {neg_sawtooth_table,  "NEG_SAWTOOTH"}};   /* WAVEFORM_NEG_SAWTOOTH */

  static void my_sprintf(char * udp_buf, int8_t value) {
    /* Fill the buffer with 4 ASCII chars */
    if (value < 0) {
      *udp_buf++ = '-';
    } else {
      *udp_buf++ = '+';
    }
    value = abs(value);
    *udp_buf++ = value/100 + '0';
    value %= 100;
    *udp_buf++ = value/10 + '0';
    value %= 10;
    *udp_buf++ = value + '0';
    *udp_buf = 0;
  }

  event void Boot.booted() {
    m_serverPresent = FALSE;
      m_nodeEUI = call LocalIeeeEui64.getId();
    m_selected_waveform = m_nodeEUI.data[7] % NUMBER_OF_WAVEFORMS;

    call RadioControl.start();
    call ServerInfo.bind(SERVER_INFO_PORT);
    call Leds.led0On();
  }

  event void ServerInfo.recvfrom(struct sockaddr_in6 *from, void *data,
        uint16_t len, struct ip6_metadata *meta) {
    char addressString[20];
    uint8_t addressStringLen;

    addressStringLen = inet_ntop6(&from->sin6_addr, addressString, sizeof(addressString));
    memcpy(m_serverAddr.sin6_addr.s6_addr, from->sin6_addr.s6_addr, 16);
    m_serverAddr.sin6_port = SENSOR_DATA_PORT;
    m_serverPresent = TRUE;
    call SensorTimer.startOneShot(2);

    printf("Received data from Server with '%s'!\n", data);
    printf("Serveraddress is: %s\n", addressString);
  }

  event void SensorData.recvfrom(struct sockaddr_in6 *from, void *data,
        uint16_t len, struct ip6_metadata *meta) {
    printf("Error! Recv on sensor port");
  }

//printf("LS-Byte=0x%x; waveform=%d\n", node_mac[7], m_selected_waveform);
//printf("%d sec. waveform=%s. cnt=%d. value=%d\n", total_time, waveform_table[m_selected_waveform].str, sample_count, waveform_table[m_selected_waveform].table[sample_count]);
  event void SensorTimer.fired() {
    if (m_serverPresent) {
      uint8_t sample_count;
      uint8_t offset = 0;
      sample_count = ((m_latestASN/((1000/(TSCH_DEFAULT_TIMESLOT_LENGTH/1000)))/INTERVAL) + m_nodeEUI.data[7]) % (SIZE_OF_WAVEFORM-1);

      m_sensorString[offset++] = '"';
      my_sprintf(&m_sensorString[offset], waveform_table[m_selected_waveform].table[sample_count]);
      offset += 4;
      m_sensorString[offset++] = '"';
      m_sensorString[offset++] = '\0';

      printf("Sending: '%s'\n", m_sensorString);
      call SensorData.sendto(&m_serverAddr, m_sensorString, offset);
    }
    call SensorTimer.startOneShot(CLOCK_SECOND * INTERVAL);
  }

  async event void TknTschEvents.asn(uint32_t* asn) {
    m_latestASN = *asn;
  }

  event void RadioControl.startDone(error_t e) {}

  event void RadioControl.stopDone(error_t e) {}
}
