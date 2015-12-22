#include <MMAC.h>

module TestC
{
	uses interface Boot;
}
implementation
{
	#define uart 		E_AHI_UART_0
//	#define baud		E_AHI_UART_RATE_38400
	#define baud		E_AHI_UART_RATE_115200
	#define buf_len 	256

#ifndef JN516_SNIFFER_CHANNEL
#warning "No channel for sniffing defined"
#endif

	uint8_t tx_buffer[buf_len];
	uint8_t rx_buffer[buf_len];

	uint8_t* txbuf;
	uint16_t txlen;

	tsMacFrame rx_frame;

	void UartWriteData16(uint16_t data) {
		vAHI_UartWriteData(uart, ((uint8_t*)(&data))[1]);
		vAHI_UartWriteData(uart, ((uint8_t*)(&data))[0]);
	}

	void RadioCallback(uint32_t bitmap) {
		int k;
//		uint32_t errors = 0xFFFFFFFF;
		tsMacFrame* frame;
		if (bitmap & E_MMAC_INT_RX_COMPLETE) {
//      errors = u32MMAC_GetRxErrors();
//      if(errors == 0)
			{
				frame = &rx_frame;

				vAHI_UartWriteData(uart, 0xCA);
				vAHI_UartWriteData(uart, 0xFE);
				vAHI_UartWriteData(uart, 0xBA);
				vAHI_UartWriteData(uart, 0xBE);
				vAHI_UartWriteData(uart, frame->u8PayloadLength);
				vAHI_UartWriteData(uart, frame->u8SequenceNum);
				UartWriteData16(frame->u16FCF);
				UartWriteData16(frame->u16DestPAN);
				UartWriteData16(frame->u16SrcPAN);
				UartWriteData16(frame->uDestAddr.u16Short);
				UartWriteData16(frame->uSrcAddr.u16Short);
				UartWriteData16(frame->u16FCS);
				UartWriteData16(frame->u16Unused);
				for (k = 0; k < frame->u8PayloadLength; k++) {
					vAHI_UartWriteData(uart, frame->uPayload.au8Byte[k]);
				}
			}
		}
		vMMAC_StartMacReceive(&rx_frame,E_MMAC_RX_START_NOW);
	}

	event void Boot.booted() {
		/*bool init_success =*/ bAHI_UartEnable(uart, tx_buffer, buf_len, tx_buffer,buf_len);
		vAHI_UartSetBaudRate(uart, baud);

		vMMAC_Enable();
		vMMAC_EnableInterrupts(RadioCallback);
		vMMAC_ConfigureRadio();
		vMMAC_SetChannel(JN516_SNIFFER_CHANNEL);
		vMMAC_StartMacReceive(&rx_frame,E_MMAC_RX_START_NOW);
	}

}                              
