#include <MMAC.h>

interface Jn516Debug {
	command void led0toggle();
	command void led1toggle();

	command void serialSendTosFrame(message_t* s_msg);
	command void serialSendMmacFrame(tsMacFrame* frame);

	command void serialSendByte(uint8_t byte);
}
