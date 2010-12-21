/*
 * Copyright (c) 2007, Intel Corporation
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
 *  Authors:  Steve Ayer, Adrian Burns
 *            February, 2007
 */
/**
 * @author Steve Ayer
 * @author Adrian Burns
 * @date February, 2007
 *
 * @author Mike Healy
 * @date April 20, 2009 - ported to TinyOS 2.x 
 */



#include "RovingNetworks.h"

interface Bluetooth {

   /* write SPP (Serial Port Profile) data to the connected BT device */
  // note: max message length is 128 bytes, beyond that msg_append_buf wraps
   command error_t write(const uint8_t *buf, uint8_t len);

   /* after this command is called there will be no link to the connected device */
   command error_t disconnect();

   /* commands useful for Master(client) applications only */
   /* do an BT Inquiry to discover all listening devices within range */
   command void discoverDevices();

   /* connect to a specific device that was previously discovered */
   command error_t connect(uint8_t * addr);

   // enum SLAVE_MODE, MASTER_MODE, TRIGGER_MASTER_MODE, AUTO_MASTER_MODE
   command void setRadioMode(uint8_t mode);           

   command void setDiscoverable(bool disc);
   command void setEncryption(bool enc);
   command void setAuthentication(bool auth);
   command void setName(char * name);                  // max 16 chars
   command void setPIN(char * name);                   // max 16 chars
   command void setServiceClass(char * class);         // max 4 chars (hex word)
   command void setServiceName(char * name);         // max 16 chars 
   command void setDeviceClass(char * class);         // max 4 chars (hex word)
   command void disableRemoteConfig(bool disableConfig);
   /*
    * rate_factor is baudrate * 0.004096, e.g. to set 115200, pass in "472"
    */
   command void setRawBaudrate(char * rate_factor);      // max 4 chars, must be integer

   /* 
    * provide one of the following as a string argument:  
    * { 1200, 2400, 4800, 9600, 19.2, 38.4, 57.6, 115K, 230K, 460K, 921K } 
    */
   command void setBaudrate(char * new_baud); 

   /* save power by minimising time Inquiry/Page scanning, call these commands from */
   /* your StdControl.init() - module reset necessary for changes to take effect */
   command void setPagingTime(char * hexval_time); // max 4 chars (hex word)
   command void setInquiryTime(char * hexval_time); // max 4 chars (hex word)
   command void resetDefaults();

   /* whether or not it succeeded */
   async event void connectionMade(uint8_t status);
   async event void connectionClosed(uint8_t reason);
   async event void commandModeEnded();
   /*
    * buffered data depends upon line demarcation or eot for this...
    *     event void dataAvailable(uint8_t * data, uint16_t len);
    * and this...
    *    event void discoveryStatus(uint8_t * devices);
    *
    */
   async event void dataAvailable(uint8_t data);
   event void writeDone();
}


