#include <MMAC.h>

#ifndef JN516_SNIFFER_CHANNEL
  #define JN516_SNIFFER_CHANNEL 11
  #warning "No channel for sniffing defined"
#endif

#define LED_INIT() vAHI_DioSetDirection(0, 1 << 2); vAHI_DioSetDirection(0, 1 << 3); vAHI_DioSetDirection(0, 1 << 16); vAHI_DioSetDirection(0, 1 << 17); CLEAR_PIN(16); CLEAR_PIN(17);
#define SET_PIN(pin) vAHI_DioSetOutput(0, 1 << (pin))
#define CLEAR_PIN(pin) vAHI_DioSetOutput(1 << (pin), 0)
#define LEDS_ON() SET_PIN(2); SET_PIN(3); SET_PIN(17);
#define LEDS_OFF() CLEAR_PIN(2); CLEAR_PIN(3); CLEAR_PIN(17);

#define UART        E_AHI_UART_0
#define BAUD        E_AHI_UART_RATE_115200
#define BUF_LEN     256


module SnifferC
{
  uses interface Boot;
  uses interface Leds;
}
implementation
{

  typedef struct {
    uint32_t timestamp;
    tsPhyFrame phyFrame;
  } recvPacket_t;

  // Function signatures
  void uartCallback(uint32 u32DeviceId, uint32 u32ItemBitmap);
  void radioCallback(uint32_t bitmap);
  void timerCallback(uint32 u32DeviceId, uint32 u32ItemBitmap);

  // Variables
  uint8_t tx_buffer[BUF_LEN];
  uint8_t rx_buffer[BUF_LEN];
  recvPacket_t recvPackets[10];
  uint8_t numRecvPackets;
  uint8_t recvStart = 0;
  uint8_t recvEnd = 0;

  uint16_t txlen;

  uint32_t seconds = 0;
  uint8_t led_state = 0;


  // Functions
  void uartCallback(uint32 u32DeviceId, uint32 u32ItemBitmap) {
    uint8_t buffer[4];
    uint8_t i;
    uint16_t remaingBytes;
    if (u32ItemBitmap & E_AHI_UART_INT_RXDATA) {
      if (0x0004 == u16AHI_UartBlockReadData(UART, buffer, sizeof(buffer))) {
        if ((buffer[0] == 0xca) && (buffer[1] == 0xfe) && (buffer[2] == 0xba)) {
          uint8_t channel = buffer[3];
          if (led_state++ % 2 == 0){
            LEDS_ON();
          } else {
            LEDS_OFF();
          }
          vMMAC_SetChannel(channel);
          remaingBytes =  u16AHI_UartReadRxFifoLevel(UART);
          for (i=0; i < remaingBytes; i++) {
            u8AHI_UartReadData(UART);
          }
        }
      }
    }
  }

  task void sendPacket() {
      int i;
      tsPhyFrame* frame;
      uint8_t *ptr;

      atomic {
        if (numRecvPackets == 0)
          return;
      }

      frame = &(recvPackets[recvEnd].phyFrame);
      ptr = (uint8_t *) &(recvPackets[recvEnd].timestamp);

      vAHI_UartWriteData(UART, 0xCA);
      vAHI_UartWriteData(UART, 0xFE);
      vAHI_UartWriteData(UART, 0xBA);
      vAHI_UartWriteData(UART, 0xBE);

      vAHI_UartWriteData(UART, ptr[0]);
      vAHI_UartWriteData(UART, ptr[1]);
      vAHI_UartWriteData(UART, ptr[2]);
      vAHI_UartWriteData(UART, ptr[3]);

      vAHI_UartWriteData(UART, frame->u8PayloadLength);
      for ( i=0; i < frame->u8PayloadLength; i++) {
        vAHI_UartWriteData(UART, frame->uPayload.au8Byte[i]);
      }

      atomic {
        numRecvPackets--;
        if (numRecvPackets > 0)
          post sendPacket();
        recvEnd = (recvEnd + 1) % 10;
      }

  }

  void radioCallback(uint32_t bitmap) {
    tsPhyFrame* frame;
    uint32_t radioTime = u32MMAC_GetRxTime();

    if (numRecvPackets >= 9) {
      return;
    }
    numRecvPackets++;
    recvPackets[recvStart].timestamp = radioTime;
    post sendPacket();

    recvStart = (recvStart + 1 ) % 10;
    frame = &(recvPackets[recvStart].phyFrame);

    vMMAC_StartPhyReceive(frame, E_MMAC_RX_START_NOW);
  }

  event void Boot.booted() {
    LED_INIT();

    // UART
    bAHI_UartEnable(UART, tx_buffer, BUF_LEN, rx_buffer, BUF_LEN);
    vAHI_UartSetBaudRate(UART, BAUD);
    if (UART == E_AHI_UART_0)
      vAHI_Uart0RegisterCallback(uartCallback);
    else if (UART == E_AHI_UART_1)
      vAHI_Uart1RegisterCallback(uartCallback);
    vAHI_UartSetInterrupt(UART, 0, 0, 0, 1, E_AHI_UART_FIFO_LEVEL_4);

    // RADIO
    vMMAC_Enable();
    vMMAC_EnableInterrupts(radioCallback);
    vMMAC_ConfigureRadio();
    vMMAC_SetChannel(JN516_SNIFFER_CHANNEL);
    vMMAC_StartPhyReceive(&(recvPackets[recvStart].phyFrame), E_MMAC_RX_START_NOW);

  }
}
