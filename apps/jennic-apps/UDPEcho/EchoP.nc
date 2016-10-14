#include <lib6lowpan/ip.h>

module EchoP {
	uses {
		interface Boot;
		interface Leds;
		interface SplitControl as RadioControl;
		interface UDP as Echo;
	}
} implementation {

	event void Boot.booted() {
		call RadioControl.start();
		call Echo.bind(7);
		call Leds.led0On();
	}

	event void Echo.recvfrom(struct sockaddr_in6 *from, void *data,
			  uint16_t len, struct ip6_metadata *meta) {
		call Echo.sendto(from, data, len);
	}

	event void RadioControl.startDone(error_t e) {}

	event void RadioControl.stopDone(error_t e) {}
}
