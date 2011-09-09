/*
 * Copyright (c) 2010, Shimmer Research, Ltd.
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:

 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * Neither the name of Shimmer Research, Ltd. nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.

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
 *
 * @author Steve Ayer
 * @date   September, 2010
 */

module Fgpmmopa6bP {
  provides {
    interface Init;
    interface Gps;
  }
  uses { 
    interface HplMsp430Usart as UARTControl;
    interface HplMsp430UsartInterrupts as UARTData;
  }
}

implementation {
  extern int sprintf(char *str, const char *format, ...) __attribute__ ((C));

  char databuf0[256], databuf1[256], * scout, cmdstring[128];
  uint8_t current_buffer, toSend, charsSent; 
  bool transmissionComplete;

  task void send_command();

  task void setupUART() {
    msp430_uart_union_config_t RN_uart_config = { 
      { ubr: UBR_1MHZ_115200, umctl: UMCTL_1MHZ_115200, 
	ssel: 0x02, pena: 0, pev: 0, spb: 0, clen: 1, 
	listen: 0, mm: 0, ckpl: 0, urxse: 0, urxeie: 0, 
	urxwie: 0,  utxe : 1, urxe :1 } 
    };

    call UARTControl.setModeUart(&RN_uart_config); // set to UART mode

    call UARTControl.enableTxIntr();
    call UARTControl.enableRxIntr();
  }

  command error_t Init.init() {

    TOSH_SET_PROG_OUT_PIN();

    TOSH_MAKE_ADC_6_INPUT();

    transmissionComplete = FALSE;

    post setupUART();

    call Gps.enable();

    return SUCCESS;
  }

  command void Gps.enable() {
    scout = databuf0;
    current_buffer = 0;

    TOSH_CLR_PROG_OUT_PIN();
  }

  command void Gps.disable() {
    TOSH_SET_PROG_OUT_PIN();
  }

  command void Gps.disableBus(){
    call UARTControl.disableUart();
  }

  command void Gps.enableBus(){
    post setupUART();
  }

  uint8_t byteCRC(char * str) 
  {
    register uint8_t i;
    uint8_t sum = 0, len;
    
    len = strlen(str);

    for(i = 0; i < len; i++)
      sum = sum ^ *(str + i);
    
    return sum;
  }

  /*
   * string of boolean on/off switches for sentences, in order
   * 0 NMEA_SEN_GLL, // GPGLL interval - Geographic Position - Latitude longitude
   * 1 NMEA_SEN_RMC, // GPRMC interval - Recomended Minimum Specific GNSS
   *   Sentence
   * 2 NMEA_SEN_VTG, // GPVTG interval - Course Over Ground and Ground Speed
   * 3 NMEA_SEN_GGA, // GPGGA interval - GPS Fix Data
   * 4 NMEA_SEN_GSA, // GPGSA interval - GNSS DOPS and Active Satellites
   * 5 NMEA_SEN_GSV, // GPGSV interval - GNSS Satellites in View
   * 18 NMEA_SEN_MCHN, // PMTKCHN interval \u2013 GPS channel status
   */
  command void Gps.restrictNMEASentences() {
    uint8_t crc;
    char cmd[128];

    sprintf(cmd, "$PMTK314,0,1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0");

    crc = byteCRC(cmd + 1);
    sprintf(cmdstring, "%s*%02X\r\n", cmd, crc);
    
    post send_command();
  }

  command void Gps.resetNMEASentences() {
    sprintf(cmdstring, "$PMTK314,-1*04\r\n");

    post send_command();
  }

  /*
   * range is 0/ 0.2/ 0.4/ 0.6/ 0.8/ 1.0/1.5/2.0 (m/s) 
   * e.g.
   * $PMTK397,0.20*<checksum><CR><LF>
   * $PMTK397,0*<checksum><CR><LF>
   */
  command void Gps.setNavThreshold() {
    uint8_t crc;
    char cmd[128];

    sprintf(cmd, "$PMTK397,0");
    crc = byteCRC(cmd + 1);
    sprintf(cmdstring, "%s*%02X\r\n", cmd, crc);

    post send_command();
  }

  command void Gps.getNavThreshold() {
    sprintf(cmdstring, "$PMTK447*35\r\n");

    post send_command();
  }

  // tell it to come up in hot start mode
  command void Gps.setHotStart() {
    sprintf(cmdstring, "$PMTK101*32\r\n");

    post send_command();
  }

  // datarate in milliseconds, min 100
  command void Gps.setDatarate(uint16_t datarate) { 
    uint8_t crc;
    char cmd[128];

    sprintf(cmd, "$PMTK300,%d,0,0,0,0", datarate);
    crc = byteCRC(cmd + 1);
    sprintf(cmdstring, "%s*%02X\r\n", cmd, crc);

    post send_command();
  }

  task void tell_app() {
    if(current_buffer == 0)
      signal Gps.NMEADataAvailable(databuf1);
    else
      signal Gps.NMEADataAvailable(databuf0);
  }

  async event void UARTData.rxDone(uint8_t data) {        
    if(!call UARTControl.isUart())
      return;
    *scout = data;
    scout++;

    if(*(scout - 1) == '\n'){
      *(scout - 2) = '\0';

      if(current_buffer == 0){
	scout = databuf1;
	current_buffer = 1;
      }
      else{
	scout = databuf0;
	current_buffer = 0;
      }

      post tell_app();
    }
  }

  task void sendOneChar() {
    if(charsSent < toSend)
      call UARTControl.tx(cmdstring[charsSent++]);
    else{
      transmissionComplete = TRUE;
    }
  }

  task void send_command() {
    toSend = strlen(cmdstring) + 1;
    charsSent = 0;
    transmissionComplete = FALSE;
    post sendOneChar();
  }
 
  async event void UARTData.txDone() {
    if(!call UARTControl.isUart())
      return;
    if(!transmissionComplete) {
      post sendOneChar();
    }
  }
}
