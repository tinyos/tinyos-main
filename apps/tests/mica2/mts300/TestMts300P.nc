#include "Timer.h"
#include "XMTS300.h"
#include "mts300.h"

module TestMts300P
{
  uses
  {
    interface Leds;
    interface Boot;
    interface Timer<TMilli> as MTS300Timer;
    // communication
    interface SplitControl as RadioControl;
    interface Packet as RadioPacket;
    interface AMSend as RadioSend;

    interface SplitControl as UartControl;
    interface Packet as UartPacket;
    interface AMSend as UartSend;
    // sensor components
    interface Mts300Sounder as Sounder;
   	interface Read<uint16_t> as Vref; //!< voltage
    interface Read<uint16_t> as Light;
    interface Read<uint16_t> as Temp;
   	interface Read<uint16_t> as Microphone; //!< Mic sensor
   	interface Read<uint16_t> as AccelX; //!< Accelerometer sensor
   	interface Read<uint16_t> as AccelY; //!< Accelerometer sensor
   	interface Read<uint16_t> as MagX; //!< magnetometer sensor
   	interface Read<uint16_t> as MagY; //!< magnetometer sensor

  }
}
implementation
{

  enum
  {
  	STATE_IDLE = 0,
  	STATE_VREF_START,
  	STATE_VREF_READY,      //!< smaple complete
  	STATE_LIGHT_START,
  	STATE_LIGHT_READY,     //!< smaple complete
  	STATE_TEMP_START,
  	STATE_TEMP_READY,      //!< smaple complete
  	STATE_MIC_START,
  	STATE_MIC_READY,      //!< smaple complete
  	STATE_ACCELX_START,
  	STATE_ACCELX_READY,      //!< smaple complete
  	STATE_ACCELY_START,
  	STATE_ACCELy_READY,      //!< smaple complete
  	STATE_MAGX_START,
  	STATE_MAGX_READY,      //!< smaple complete
  	STATE_MAGY_START,
  	STATE_MAGY_READY,      //!< smaple complete
  };

  bool sending_packet;
  bool packet_ready;
  uint8_t state;
  uint16_t counter = 0;
  message_t packet;
  Mts300Msg* pMsg;

  // Zero out the accelerometer, chrl@20070213
  norace uint16_t accel_ave_x, accel_ave_y;
  norace uint8_t accel_ave_points;


//////////////////////////////////////////////////////////////////////////////
//
//  packet sending
//
//////////////////////////////////////////////////////////////////////////////
  task void send_msg()
  {
    atomic packet_ready = FALSE;
    // check length of the allocated buffer to see if it is enough for our packet
    if (call RadioPacket.maxPayloadLength() < sizeof(Mts300Msg))
    {
      return ;
    }
    // OK, the buffer is large enough
    //pMsg->vref = counter;
    if (call UartSend.send(AM_BROADCAST_ADDR, &packet, sizeof(Mts300Msg)) == SUCCESS)
    {
      sending_packet = TRUE;
      call Leds.led2On();
    }
  }

//////////////////////////////////////////////////////////////////////////////
//
//  basic control routines
//
//////////////////////////////////////////////////////////////////////////////
  event void Boot.booted()
  {
    sending_packet = FALSE;
    packet_ready = FALSE;
    state = STATE_IDLE;
    pMsg = (Mts300Msg*)call RadioPacket.getPayload(&packet, NULL);

    // Zero out the accelerometer, chrl@20070213
    accel_ave_x = 0;
    accel_ave_y = 0;
    accel_ave_points = ACCEL_AVERAGE_POINTS;

    call RadioControl.start();
    call UartControl.start();
  }

  event void RadioControl.startDone(error_t err)
  {
    if (err != SUCCESS)
    {
      call RadioControl.start();
    }
  }

  event void RadioControl.stopDone(error_t err)
  {
    // do nothing
  }

  event void UartControl.startDone(error_t err)
  {
    if (err == SUCCESS)
    {
      call Sounder.beep(1000);
      call MTS300Timer.startPeriodic( 1000 );
    }
    else
    {
      call UartControl.start();
    }
  }

  event void UartControl.stopDone(error_t err)
  {
    // do nothing
  }

//////////////////////////////////////////////////////////////////////////////
//
//  timer control routines
//
//////////////////////////////////////////////////////////////////////////////
  event void MTS300Timer.fired()
  {
    uint8_t l_state;
    atomic l_state = state;

    // Zero out the accelerometer, chrl@20070213
    if (accel_ave_points >0)
    {
      if (accel_ave_points == 1)
      {
        call MTS300Timer.stop();
        call MTS300Timer.startPeriodic(1000);
      }
      atomic state = STATE_ACCELX_START;
      call AccelX.read();
      return ;
    }

    call Leds.led1Toggle();

    if (sending_packet) return ;

    if (l_state == STATE_IDLE)
    {
      atomic state = STATE_VREF_START;
      call Vref.read();
      return ;
    }
  }

  /**
   * reference voltage data read
   *
   */
  event void Vref.readDone(error_t result, uint16_t data)
  {
    if (result == SUCCESS)
    {
      pMsg->vref = data;
    }
    else
    {
      pMsg->vref = 0;
    }
      atomic state = STATE_LIGHT_START;
      call Light.read();
  }

  /**
   * Light data read
   *
   */
  event void Light.readDone(error_t result, uint16_t data)
  {
    if (result == SUCCESS)
    {
      pMsg->light = data;
    }
    else
    {
      pMsg->light = 0;
    }
    atomic state = STATE_TEMP_START;
    call Temp.read();
//    atomic state = STATE_MIC_START;
//    call Microphone.read();
  }

  /**
   * Temperature data read
   *
   */
  event void Temp.readDone(error_t result, uint16_t data)
  {
    if (result == SUCCESS)
    {
      pMsg->thermistor = data;
    }
    else
    {
      pMsg->thermistor = 0;
    }
    atomic state = STATE_MIC_START;
    call Microphone.read();
  }

  /**
   * Microphone data read
   *
   */
  event void Microphone.readDone(error_t result, uint16_t data)
  {
    if (result == SUCCESS)
    {
      pMsg->mic = data;
    }
    else
    {
      pMsg->mic = 0;
    }
//    atomic packet_ready = TRUE;
    atomic state = STATE_ACCELX_START;
    call AccelX.read();
  }

  /**
   * AccelX data read
   *
   */
  event void AccelX.readDone(error_t result, uint16_t data)
  {
    // Zero out the accelerometer, chrl@20061207
    if (accel_ave_points>0)
    {
      accel_ave_x = accel_ave_x + data;
      call AccelY.read();
      return ;
    }
      
    if (result == SUCCESS)
    {
      pMsg->accelX = data - accel_ave_x;
    }
    else
    {
      pMsg->accelX = 0;
    }
    atomic state = STATE_ACCELY_START;
    call AccelY.read();
  }

  /**
   * AccelY data read
   *
   */
  event void AccelY.readDone(error_t result, uint16_t data)
  {
    // Zero out the accelerometer, chrl@20061207
    if (accel_ave_points>0)
    {
      accel_ave_y = accel_ave_y + data;
      accel_ave_points--;
      if(accel_ave_points == 0)
      {
        accel_ave_x = accel_ave_x / ACCEL_AVERAGE_POINTS - 450;
        accel_ave_y = accel_ave_y / ACCEL_AVERAGE_POINTS - 450;
      }
      atomic state = STATE_IDLE;
      return ;
    }

    if (result == SUCCESS)
    {
      pMsg->accelY = data - accel_ave_y;
    }
    else
    {
      pMsg->accelY = 0;
    }
    atomic state = STATE_MAGX_START;
    call MagX.read();
  }

  /**
   * MagX data read
   *
   */
  event void MagX.readDone(error_t result, uint16_t data)
  {
    if (result == SUCCESS)
    {
      pMsg->magX = data;
    }
    else
    {
      pMsg->magX = 0;
    }
    atomic state = STATE_MAGY_START;
    call MagY.read();
  }

  /**
   * MagY data read
   *
   */
  event void MagY.readDone(error_t result, uint16_t data)
  {
    if (result == SUCCESS)
    {
      pMsg->magY = data;
    }
    else
    {
      pMsg->magY = 0;
    }
    atomic packet_ready = TRUE;
    post send_msg();
  }

  /**
   * Data packet sent to RADIO
   *
   */
  event void RadioSend.sendDone(message_t* bufPtr, error_t error)
  {
    if (&packet == bufPtr)
    {
      call Leds.led2Off();
    }
    else
    {
      call Leds.led0On();
    }
    sending_packet = FALSE;
    atomic state = STATE_IDLE;
  }

  /**
   * Data packet sent to UART
   *
   */
  event void UartSend.sendDone(message_t* bufPtr, error_t error)
  {
    if (&packet == bufPtr)
    {
      if (call RadioSend.send(AM_BROADCAST_ADDR, &packet, sizeof(Mts300Msg)) != SUCCESS)
      {
        call Leds.led0On();
        sending_packet = FALSE;
        atomic state = STATE_IDLE;
      }
    }
    else
    {
      call Leds.led0On();
      sending_packet = FALSE;
      atomic state = STATE_IDLE;
    }
  }

// end of the implementation
}
