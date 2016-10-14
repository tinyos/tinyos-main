#include "TestSerial.h"

module TestSerialC {
  uses {
    interface SplitControl as Control;
    interface Leds;
    interface Boot;
    interface AMSend;
    interface Timer<TMilli> as MilliTimer;
    interface Packet;
  }
}
implementation {

	message_t packet;

	bool locked = FALSE;
	uint16_t counter = 0;

	event void Boot.booted() {
		call Control.start();
	}

	event void MilliTimer.fired() {
		counter++;
		if (locked) {
			return;
		}
		else {
			test_serial_msg_t* rcm = (test_serial_msg_t*)call Packet.getPayload(&packet, sizeof(test_serial_msg_t));
			if (rcm == NULL) {return;}
			if (call Packet.maxPayloadLength() < sizeof(test_serial_msg_t)) {
				return;
			}

			rcm->counter = counter;
			if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(test_serial_msg_t)) == SUCCESS) {
				locked = TRUE;
			}
		}
	}

	event void AMSend.sendDone(message_t* bufPtr, error_t error) {
		if (&packet == bufPtr) {
			locked = FALSE;
		}
	}

	event void Control.startDone(error_t err) {
		if (err == SUCCESS) {
			call MilliTimer.startPeriodic(1000);
		}
	}

	event void Control.stopDone(error_t err) {}
}



