/*
 * Copyright (c) 2007 Romain Thouvenin <romain.thouvenin@gmail.com>
 * Published under the terms of the GNU General Public License (GPLv2).
 */

#include "dymo_packet.h"

/**
 * DymoPacketM - Implementation of the DYMO packets format.
 *
 * @author Romain Thouvenin
 */

module DymoPacketM {
  provides {
    interface DymoPacket;
    interface PacketMaker; //For tests and debugging
  }
  uses interface Packet;
}
//TODO generalize size values
implementation {
  message_t * currentMsg;
  message_t * processedMsg;

  /* Local functions */
  void    create_block(nx_uint8_t * payload, const rt_info_t * info);
  uint8_t block_size(nx_uint8_t * block);
  uint8_t block_info_size(nx_uint8_t * block);
  uint8_t block_header_size(nx_uint8_t * block);
  uint8_t block_num_addr(nx_uint8_t * block);
  void    block_get_info(nx_uint8_t * block, uint8_t pos, rt_info_t * info, bool update);
  nx_uint8_t * block_get_pointer(nx_uint8_t * block, uint8_t pos, uint8_t * size);
  bool block_can_contain(nx_uint8_t * block, const rt_info_t * info);
  void block_add_info(nx_uint8_t * block, const rt_info_t * info);
  void move_data(nx_uint8_t * data, uint8_t amount, uint8_t offset);


  /*****************
   * Packet header *
   *****************/

  command dymo_msg_t DymoPacket.getType(message_t * msg){
    nx_uint8_t * p = call Packet.getPayload(msg, 1);
    return *p;
  }

  command uint16_t DymoPacket.getSize(message_t * msg){
    nx_uint8_t * p = call Packet.getPayload(msg, 3);
    return *(nx_uint16_t *)(p + 1);
  }


  /*********************
   * Creating a packet *
   *********************/

  command void DymoPacket.createRM(message_t * msg, dymo_msg_t msg_type, 
			const rt_info_t * origin, const rt_info_t * target){
    nx_uint8_t * payload = call Packet.getPayload(msg, call Packet.maxPayloadLength());
    nx_uint16_t * size_p;
    *(payload++) = msg_type;
    size_p = (nx_uint16_t *) payload;
    payload += 2;
    *(payload++) = DYMO_HOPLIMIT;
    *(payload++) = 0;

    create_block(payload, target);
   
    if(origin){
      if(block_can_contain(payload, origin)){
	block_add_info(payload, origin);
	*size_p = block_size(payload);
      } else {
	*size_p = block_size(payload);
	payload += *size_p;
	create_block(payload, origin);
	*size_p += block_size(payload);
      }
    } else {
      *size_p = block_size(payload);
    }

    //size of msg header
    //it is here to save a few instructions or a byte
    *size_p += 5; 
  }

  command error_t DymoPacket.addInfo(message_t * msg, const rt_info_t * info){
    nx_uint8_t * payload = call Packet.getPayload(msg, call Packet.maxPayloadLength());
    nx_uint16_t * size_p = (nx_uint16_t *)(payload + 1);
    nx_uint8_t * block = payload + 5;
    uint8_t bsize;

    while(block < payload + *size_p){
      //We don't want to add something before the origin
      if ( ((block > payload + 5) && block_can_contain(block, info))
	   || ((block == payload + 5) && (block_num_addr(block) > 1)) ) {

	uint8_t isize = block_info_size(block);
	if(*size_p + isize > call Packet.maxPayloadLength()){
	  return ESIZE;
	} else {
	  bsize = block_size(block);
	  move_data(block + bsize, payload + *size_p - (block + bsize), isize);
	  block_add_info(block, info);
	  *size_p += isize;
	  return SUCCESS;
	}

      } else {
	block += block_size(block);
      }
    }

    create_block(block, info);
    bsize = block_size(block);
    if(*size_p +  bsize > call Packet.maxPayloadLength()){
      return ESIZE;
    } else {
      *size_p += bsize;
      return SUCCESS;
    }
  }


  /***********************
   * Processing a packet *
   ***********************/

  task void processMessage(){
    nx_uint8_t * payload = call Packet.getPayload(currentMsg, call Packet.maxPayloadLength());
    nx_uint8_t * end = payload + *(nx_uint16_t *)(payload+1);
    nx_uint8_t * fw_payload = NULL;
    nx_uint16_t * fw_size = NULL;
    nx_uint8_t *fw_block, *info_p;
    rt_info_t info;
    uint8_t i,n,s;
    bool first_block = 1;
    proc_action_t action;

    payload += 3;
    *(payload++) -= 1; //decr hopL
    *(payload++) += 1; //incr hopC
    action = signal DymoPacket.hopsProcessed(currentMsg, *(payload-2), *(payload-1));
    if(processedMsg){
      if(action != ACTION_DISCARD_MSG){
	fw_payload = call Packet.getPayload(processedMsg, call Packet.maxPayloadLength());
	memcpy(fw_payload, payload - 5, 5);
	fw_size = (nx_uint16_t *)(fw_payload + 1);
	*fw_size = 5;
	fw_payload += 5;
      } else {
	processedMsg = NULL;
      }
    }

    while(payload < end){
      fw_block = NULL;
      n = block_num_addr(payload);

      for(i=0;i<n;i++){
	block_get_info(payload, i, &info, !first_block || i);
	action = signal DymoPacket.infoProcessed(currentMsg, &info);

	if(processedMsg){
	  switch(action){
	  case ACTION_KEEP:
	    if(!fw_block){
	      s = block_header_size(payload);
	      memcpy(fw_payload, payload, s);
	      fw_block = fw_payload;
	      *(fw_block+1) = 0;
	      fw_payload += s;
	    }
	    info_p = block_get_pointer(payload, i, &s);
	    memcpy(fw_payload, info_p, s);
	    fw_payload += s;
	    *(fw_block+1) += 1; //increments NumAddr
	    break;

	  case ACTION_DISCARD_MSG:
	    processedMsg = NULL;
	  default:
	  }
	}//if

      }//for
      payload += block_size(payload);
      first_block = 0;
      if(fw_block)
	*fw_size += block_size(fw_block);
    }
    
    signal DymoPacket.messageProcessed(currentMsg);
  }

  command void DymoPacket.startProcessing(message_t * msg, message_t * newmsg){
    currentMsg = msg;
    processedMsg = newmsg;
    post processMessage();
  }



  //TODO return block_size, it is always needed after a block creation
  void create_block(nx_uint8_t * payload, const rt_info_t * info){
    uint8_t semantics;

    semantics = BLOCK_HEAD;
    if(info->seqnum)
      semantics |= BLOCK_SEQNUM;
    if(info->has_hopcnt)
      semantics |= BLOCK_HOPCNT;

    *(payload++) = semantics;
    *(payload++) = 1;
    *(nx_addr_t *)payload = info->address;
    payload += sizeof(addr_t);
    if(info->seqnum){
      *(nx_seqnum_t *)payload = info->seqnum;
      payload += 2;
    }
    if(info->has_hopcnt){
      *(payload++) = info->hopcnt;
    }
  }

  void block_add_info(nx_uint8_t * block, const rt_info_t * info){
    uint8_t semantics = *block;
    nx_uint8_t * size_p = block + 1;
    block += block_size(block);
    *size_p += 1;
    if(semantics & BLOCK_HEAD){
      *block = info->address % 256;
      block++;
    } else {
      *(nx_addr_t *)block = info->address;
      block += sizeof(addr_t);
    }

    if(semantics & BLOCK_SEQNUM){
      *(nx_seqnum_t *)block = info->seqnum;
      block += sizeof(seqnum_t);
    }

    if(semantics & BLOCK_HOPCNT){
      *block = info->hopcnt;
    }
  }

  bool block_can_contain(nx_uint8_t * block, const rt_info_t * info){
    if( (*block & BLOCK_SEQNUM) && !info->seqnum )
      return 0;
    if( !(*block & BLOCK_SEQNUM) && info->seqnum )
      return 0;

    if( (*block & BLOCK_HOPCNT) && !info->has_hopcnt )
      return 0;
    if( !(*block & BLOCK_HOPCNT) && info->has_hopcnt )
      return 0;

    if( (*block & BLOCK_HEAD) && (*(block + 2) != (info->address / 256)) )
      return 0;

    return 1;
  }

  uint8_t block_info_size(nx_uint8_t * block){
    uint8_t result = 1;
    if(!(*block & BLOCK_HEAD))
      result++;
    if(*block & BLOCK_SEQNUM)
      result += 2;
    if(*block & BLOCK_HOPCNT)
      result++;
    //TODO add max age
    return result;
  }

  uint8_t block_header_size(nx_uint8_t * block){
    if(*block & BLOCK_HEAD)
      return 3;
    else
      return 2;
  }

  uint8_t block_num_addr(nx_uint8_t * block){
    return *(block + 1);
  }

  uint8_t block_size(nx_uint8_t * block){
    uint8_t result = 2;
    if(*block & BLOCK_HEAD){
      result++;
    }
    return result + block_num_addr(block) * block_info_size(block);
  }

  nx_uint8_t * block_get_pointer(nx_uint8_t * block, uint8_t pos, uint8_t * size){
    if(size){
      *size = block_info_size(block);
      return block + block_header_size(block) + pos * (*size);
    } else {
      return block + block_header_size(block) + pos * block_info_size(block);
    }
  }

  void block_get_info(nx_uint8_t * block, uint8_t pos, rt_info_t * info, bool update){
    nx_uint8_t * semantics = block;
    block = block_get_pointer(block, pos, NULL);
    
    if(*semantics & BLOCK_HEAD){
      info->address = *(semantics + 2) * 256 + *block;
      block++;
    } else {
      info->address = *(nx_addr_t *)block;
      block += sizeof(addr_t);
    }

    if(*semantics & BLOCK_SEQNUM){
      info->seqnum = *(nx_seqnum_t *)block;
      block += sizeof(seqnum_t);
    } else {
      info->seqnum = 0;
    }

    if(*semantics & BLOCK_HOPCNT){
      info->has_hopcnt = 1;
      if(update)
	*block += 1;
      info->hopcnt = *block;
      block++;
    } else {
      info->has_hopcnt = 0;
    }
  }

  void move_data(nx_uint8_t * data, uint8_t amount, uint8_t offset){
    nx_uint8_t * newdata = data + amount + offset;
    data += amount;
    for(; amount > 0; amount--)
      *--newdata = *--data;
  }


  /**************
   * PakerMaker *
   **************/

  command uint16_t PacketMaker.getSize(message_t * msg){
    return call DymoPacket.getSize(msg);
  }

  command void PacketMaker.createRM(message_t * msg, dymo_msg_t msg_type, 
				   const rt_info_t * origin, const rt_info_t * target){
    call DymoPacket.createRM(msg, msg_type, origin, target);
  }

  command error_t PacketMaker.addInfo(message_t * msg, const rt_info_t * info){
    return call DymoPacket.addInfo(msg, info);
  }
}
