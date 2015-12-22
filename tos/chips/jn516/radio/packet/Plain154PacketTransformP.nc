#include "message.h"
#include "Jn516.h"
//#include "plain154_message_structs.h"
#include "plain154_values.h"

module Plain154PacketTransformP {
	provides {
		interface Plain154PacketTransformMac;
	}
}
implementation {

	async command error_t Plain154PacketTransformMac.Plain154ToMMAC(plain154_txframe_t* from, tsMacFrame* to) {
		uint8_t tmp;

		to->u8PayloadLength = from->payloadLen;
		to->u8SequenceNum =  from->header->dsn;
		to->u16FCF = from->header->fcf1 | (from->header->fcf2 << 8);
		to->u16DestPAN = (uint16) from->header->destpan;
		to->u16SrcPAN = (uint16) from->header->srcpan;

		switch (from->header->fcf2 & PLAIN154_FC2_MASK_ADDRMODE_DEST) {
			case PLAIN154_FC2_DEST_SHORT:
				to->uDestAddr.u16Short = (uint16) from->header->dest.short_addr;
				break;
			case PLAIN154_FC2_DEST_EXTENDED:
				to->uDestAddr.sExt.u32L = (uint32) (from->header->dest.long_addr & 0xFFFFFFFF);
				to->uDestAddr.sExt.u32H = (uint32) ((from->header->dest.long_addr >> 32) & 0xFFFFFFFF);
				break;
			case PLAIN154_ADDR_NOT_PRESENT:
				// nothing to do
				break;
			default:
				return EINVAL;
		}

		switch (from->header->fcf2 & PLAIN154_FC2_MASK_ADDRMODE_SRC) {
			case PLAIN154_FC2_SRC_SHORT:
				to->uSrcAddr.u16Short = (uint16) from->header->src.short_addr;
				break;
			case PLAIN154_FC2_SRC_EXTENDED:
				to->uSrcAddr.sExt.u32L = (uint32) (from->header->src.long_addr & 0xFFFFFFFF);
				to->uSrcAddr.sExt.u32H = (uint32) ((from->header->src.long_addr >> 32) & 0xFFFFFFFF);
				break;
			case PLAIN154_ADDR_NOT_PRESENT:
				// nothing to do
				break;
			default:
				return EINVAL;
		}

		for (tmp = 0; tmp < from->payloadLen; tmp++) {
		  to->uPayload.au8Byte[tmp] = from->payload[tmp];
		}

		return SUCCESS;
	}

	/**
	 * Convert the tsMacFrame format to message_t using plain154_header_t
	 */
	async command error_t Plain154PacketTransformMac.MMACToPlain154(tsMacFrame* from, message_t* to) {
		plain154_header_t *to_hdr = (plain154_header_t*)to; // call Jn516PacketBody.getHeader(to);
		uint8_t tmp;

		to_hdr->payloadlen = from->u8PayloadLength;
		to_hdr->fcf1 = (uint8_t) from->u16FCF & 0xFF;
		to_hdr->fcf2 = (uint8_t) ((from->u16FCF >> 8) & 0xFF);
		to_hdr->dsn = from->u8SequenceNum;
		to_hdr->destpan = from->u16DestPAN;
		to_hdr->srcpan = from->u16SrcPAN;

        switch (to_hdr->fcf2 & PLAIN154_FC2_MASK_ADDRMODE_SRC) {
            case PLAIN154_FC2_SRC_SHORT:
                to_hdr->src.short_addr = from->uSrcAddr.u16Short;
                break;
            case PLAIN154_FC2_SRC_EXTENDED:
                to_hdr->src.long_addr = from->uSrcAddr.sExt.u32L | ((uint64_t)from->uSrcAddr.sExt.u32H << 32);
                break;
            case PLAIN154_ADDR_NOT_PRESENT:
                // nothing to do
                break;
            default:
                return EINVAL;
        }

        switch (to_hdr->fcf2 & PLAIN154_FC2_MASK_ADDRMODE_DEST) {
            case PLAIN154_FC2_DEST_SHORT:
                to_hdr->dest.short_addr = from->uDestAddr.u16Short;
                break;
            case PLAIN154_FC2_DEST_EXTENDED:
                to_hdr->dest.long_addr = from->uDestAddr.sExt.u32L | ((uint64_t)from->uDestAddr.sExt.u32H << 32);
                break;
            case PLAIN154_ADDR_NOT_PRESENT:
                // nothing to do
                break;
            default:
                return EINVAL;
        }

        for (tmp = 0; tmp < from->u8PayloadLength; tmp++) {
          to->data[tmp] = from->uPayload.au8Byte[tmp];
        }

		return SUCCESS;
	}
}
