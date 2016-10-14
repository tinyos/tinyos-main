#include <MMAC.h>
#include <Jn516.h>

#ifdef _JN516_PRINTF_RADIO_154BARE
#include <blip_printf.h>
#endif

#include "plain154_message_structs.h"
#include "Timer.h"

/*
  TODO This is still a draft!

  NOTE:
  - At which points in time shall time stamps be generated? At the beginning
    and/or the end of frame?
  - The TimeConversion module needs to be implemented.
    Plain154TimeConversion<T62500hz, T32khz>.toTarget(..) converts a radio
    time stamp to a 32.768kHz clock based time stamp
*/

module Plain154_32khz32P {
	provides {
		interface Plain154PhyTx<T32khz,uint32_t>;
		interface Plain154PhyRx<T32khz,uint32_t>;
		interface Plain154PhyOff;
		interface GetSet<uint8_t> as RadioChannel;
	}
	uses {
		interface Alarm<T32khz,uint32_t>;
//		interface Ieee154Address;
//		interface Jn516PacketBody;
		interface Plain154PacketTransformMac as PacketTransform;
    interface Plain154Metadata;
	}
}
implementation {

	enum { RADIO_OFF = 0, RADIO_TX = 1, RADIO_RX = 2 } radio_state = RADIO_OFF;

	uint8_t channel = 20;

	tsMacFrame tx_frame_mmac;
	plain154_txframe_t* tx_frame_plain154;
	error_t tx_error;

	tsMacFrame rx_frame;
	message_t rx_msg;
	error_t rx_error;

	command void RadioChannel.set(uint8_t val ) {
		atomic channel = val;
	}

	command uint8_t RadioChannel.get() {
		atomic return channel;
	}

	void RadioCallback(uint32_t bitmap) @hwevent() {
    // time stamp after end of RX or TX
		atomic {
			switch( radio_state ) {
				case RADIO_TX:
					if(bitmap & E_MMAC_INT_TX_COMPLETE) {
						if(u32MMAC_GetTxErrors() == 0) {
							tx_error = SUCCESS;
						} else {
							tx_error = FAIL;
						}
						vMMAC_RadioOff();
						radio_state = RADIO_OFF;

            // TODO ?? -> 2nd part of approximate TX time stamp
            //stamp += (u32MMAC_GetTime() - stamp) / 2;

/* TODO            meta = call Plain154Metadata.getMetadata(&rx_msg);
            meta->timestamp = call TimeConversion.toTarget(stamp);
            meta->valid_timestamp = TRUE;*/
						signal Plain154PhyTx.transmitDone(tx_frame_plain154, tx_error);
					}
					break;
				case RADIO_RX:
					if(bitmap & E_MMAC_INT_RX_COMPLETE) {
						if(u32MMAC_GetRxErrors() == 0) {
							rx_error = SUCCESS;
						} else {
							rx_error = FAIL;
						}
						call PacketTransform.MMACToPlain154(&rx_frame,&rx_msg);
/* TODO              meta = call Plain154Metadata.getMetadata(&rx_msg);
              meta->timestamp = call TimeConversion.toTarget(stamp);
              meta->valid_timestamp = TRUE;*/
						signal Plain154PhyRx.received(&rx_msg);
						vMMAC_StartMacReceive(&rx_frame,
								E_MMAC_RX_START_NOW
								| E_MMAC_RX_NO_AUTO_ACK
								| E_MMAC_RX_NO_FCS_ERROR
								| E_MMAC_RX_NO_ADDRESS_MATCH
							);
					}
					break;
				default:
					// TODO handle unexpected cases
					break;
			}
		}
	}

	async event void Alarm.fired() {
		switch (radio_state) {
			case RADIO_TX:
				vMMAC_StartMacTransmit(&tx_frame_mmac,
						E_MMAC_TX_START_NOW
						| E_MMAC_TX_NO_AUTO_ACK
						| E_MMAC_TX_NO_CCA
					);
				break;
			case RADIO_RX:
				vMMAC_StartMacReceive(&rx_frame,
						E_MMAC_RX_START_NOW
						| E_MMAC_RX_NO_AUTO_ACK
						| E_MMAC_RX_NO_FCS_ERROR
						| E_MMAC_RX_NO_ADDRESS_MATCH
					);
				signal Plain154PhyRx.enableRxDone();
				break;
			default:
				break;
		}
	}

	void mmac_setup() {
		vMMAC_Enable();
		vMMAC_EnableInterrupts(RadioCallback);
		vMMAC_ConfigureRadio();
		vMMAC_SetChannel(channel);
	}

	inline bool isFutureTime(uint32_t t0, uint32_t dt) {
		if (dt == 0) {
			return FALSE;
		}
		else {
			uint32_t elapsed, now = call Alarm.getNow();
			if (now >= t0)
				elapsed = now - t0;
			else
				elapsed = ~(t0 - now) + 1;

			if (elapsed >= dt) {
				return FALSE;
			}
			else {
				return TRUE;
			}
		}
	}

	async command error_t Plain154PhyRx.enableRx(uint32_t t0, uint32_t dt) {
		atomic {
			if (radio_state != RADIO_OFF)
				return FAIL;
			radio_state = RADIO_RX;
			mmac_setup();
			if (!isFutureTime(t0, dt)) {
				signal Alarm.fired();
			}
			else {
				call Alarm.startAt(t0,dt);
			}
			return SUCCESS;
		}
	}

	async command bool Plain154PhyRx.isReceiving() {
		if( radio_state == RADIO_RX )
			return TRUE;
		else
			return FALSE;
	}


	async command error_t Plain154PhyTx.transmit(plain154_txframe_t *frame, uint32_t t0, uint32_t dt) {
		atomic {
			if( radio_state != RADIO_OFF )
				return FAIL;
			radio_state = RADIO_TX;
			mmac_setup();
			tx_frame_plain154 = frame;
			call PacketTransform.Plain154ToMMAC(frame,&tx_frame_mmac);
			if (!isFutureTime(t0, dt)) {
				signal Alarm.fired();
			}
			else {
				call Alarm.startAt(t0,dt);
			}
			return SUCCESS;
		}
	}


  async command uint32_t Plain154PhyRx.getNow() {
    return call Alarm.getNow();
  }

	async command uint32_t Plain154PhyTx.getNow() {
		return call Alarm.getNow();
	}

	task void switch_radio_off() {
		atomic {
			vMMAC_RadioOff();
			radio_state = RADIO_OFF;
			signal Plain154PhyOff.offDone();
		}
	}

	async command error_t Plain154PhyOff.off() {
		atomic {
			if( radio_state == RADIO_TX )
				return FAIL;
			if( radio_state == RADIO_OFF )
				return EALREADY;
			post switch_radio_off();
			return SUCCESS;
		}
	}

	async command bool Plain154PhyOff.isOff() {
		if( radio_state == RADIO_OFF )
			return TRUE;
		else
			return FALSE;
	}

//	event void Ieee154Address.changed() {}

	// default wiring
	default async event void Plain154PhyOff.offDone() {}
	default async event void Plain154PhyRx.enableRxDone() {}
	default async event message_t* Plain154PhyRx.received(message_t *frame) { return frame; }
	default async event void Plain154PhyTx.transmitDone(plain154_txframe_t *frame, error_t result) {}
}
