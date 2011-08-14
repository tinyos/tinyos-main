/*
 * Copyright (c) 2009 DEXMA SENSORS SL
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
 * @author: Xavier Orduna <xorduna@dexmatech.com>
 * @author: Jordi Soucheiron <jsoucheiron@dexmatech.com>
 */

generic module LedsIntensityP() {
  provides interface StdControl;
  provides interface LedsIntensity;
  uses interface Leds;
  uses interface Boot;
}
implementation
{
  enum
  {
    NUM_LEDS = 3,
    NUM_INTENSITY = 32,
    RESOLUTION = 128,
  };

  bool m_run;
  int8_t m_intensity[NUM_LEDS];
  int8_t m_accum[NUM_LEDS];
  static const int8_t m_exp[NUM_INTENSITY] = {
    0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 4, 5, 6, 7, 8, 9,
    11, 13, 16, 19, 22, 26, 30, 36, 42, 49, 58, 67, 79, 93, 108, 127,
  };


	void wait(uint16_t t) {
	  for ( ; t > 0; t-- );
	}

	void longwait( uint16_t t ) {
	  for( ; t > 0; t-- )
	    wait(0xa0);
	}

  task void dimleds()
  {
    if( m_run )
    {
      int i;
      int ledval = 0;
      for( i=NUM_LEDS-1; i>=0; i-- )
      {
		ledval <<= 1;
		if( (m_accum[i] += m_intensity[i]) >= 0 )
		{
	  		m_accum[i] -= (RESOLUTION-1);
	  		ledval |= 1;
		}
      }
      call Leds.set( ledval );
      post dimleds();
    }
    else
    {
      call Leds.set( 0 );
    }
  }

  command void LedsIntensity.set( uint8_t ledNum, uint8_t intensity )
  {
    if( ledNum < NUM_LEDS )
    {
      intensity >>= 3;
      if( intensity >= (NUM_INTENSITY-1) )
      {
		m_intensity[ledNum] = m_exp[NUM_INTENSITY-1];
		m_accum[ledNum] = 0;
      }
      else
      {
		m_intensity[ledNum] = m_exp[intensity];
		if( m_intensity[ledNum] == 0 )
	  	m_accum[ledNum] = -1;
      }
    }
  }

  command void LedsIntensity.glow(uint8_t a, uint8_t b) {
    int i;
    for (i = 1536; i > 0; i -= 4) {
      call Leds.set(a);
      longwait(i);
      call Leds.set(b);
      longwait(1536-i);
    }
  }  
  

  event void Boot.booted()
  {
    int i;
    for( i=0; i<NUM_LEDS; i++ )
    {
      m_intensity[i] = 0;
      m_accum[i] = -1;
    }
    //call Leds.init();
  }

  command error_t StdControl.start()
  {
    m_run = TRUE;
    post dimleds();
    return SUCCESS;
  }

  command error_t StdControl.stop()
  {
    m_run = FALSE;
    return SUCCESS;
  }
}
