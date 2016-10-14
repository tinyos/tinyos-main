#include "message.h"
#include <MMAC.h>
#include "plain154_message_structs.h"

interface Plain154PacketTransform {
	async command error_t Plain154ToMMAC(plain154_txframe_t* from, tsPhyFrame* to);
	async command error_t MMACToPlain154(tsPhyFrame* from, message_t* to);
}
