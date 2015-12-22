#include "message.h"
#include <MMAC.h>
#include "plain154_message_structs.h"

interface Plain154PacketTransformMac {
	async command error_t Plain154ToMMAC(plain154_txframe_t* from, tsMacFrame* to);
	async command error_t MMACToPlain154(tsMacFrame* from, message_t* to);
}
