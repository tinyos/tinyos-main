/*
 * Copyright (c) 2007 Romain Thouvenin <romain.thouvenin@gmail.com>
 * Published under the terms of the GNU General Public License (GPLv2).
 */

#include "routing.h"
#include "routing_table.h"

/**
 * DymoEngineM - Implements the algorithms to generate and process
 * DYMO messages. This the simultor version, without persistent
 * storage of the seqnum.
 *
 * @author Romain Thouvenin
 */

module DymoEngineM {
  provides {
    interface SplitControl;
  }
  uses {
    interface DymoTable;
    interface RoutingTable;
    interface DymoPacket;
    interface AMSend;
    interface AMPacket;
    interface Receive;
  }

#ifdef DYMO_MONITORING
  provides interface DymoMonitor;
  uses {
    interface Timer<TMilli>;
  }
#endif
}

implementation {
  message_t * avail_msg; //to be returned by receive
  message_t buf_avail;   //first avail_msg
  message_t buf_packet;
  rt_info_t me;
  rt_info_t buf_info;
  addr_t ignoreNeeded;
  bool busySend;

  /* for processing */
  bool busyProcess, busyIssue;
  uint8_t cur_hopcnt;
  uint8_t cur_info_pos;
  rt_info_t buf_target;
  addr_t fw_address; //set to 0 if the message must not be forwarded
  message_t fw_msg;
  bool sendRREP;

#ifdef DYMO_MONITORING
  uint32_t rreq_time;
#endif


  task void startDoneTask() {
    signal SplitControl.startDone(SUCCESS);
  }

  command error_t SplitControl.start(){
    me.address = call AMPacket.address();
    me.seqnum = 1;
    me.has_hopcnt = 1;
    me.hopcnt = 0;

    avail_msg = &buf_avail;
    ignoreNeeded = 0;
    sendRREP = FALSE;
    busyProcess = FALSE;
    busyIssue = FALSE;
    busySend = FALSE;
    buf_target.address = 0;
    
#ifdef DYMO_MONITORING
    rreq_time = 0;
#endif

    post startDoneTask();
    return SUCCESS;
  }

  void incr_seqnum(){
    if(me.seqnum == 65535)
      me.seqnum = 256;
    else
      me.seqnum++;
  }

  /* Send a RREQ for buf_info */
  task void issueRREQ(){
    atomic {
      if(busySend)
	post issueRREQ();
      else {
	busySend = TRUE;
	incr_seqnum();
	call DymoPacket.createRM(&buf_packet, DYMO_RREQ, &me, &buf_info);
	call AMSend.send(AM_BROADCAST_ADDR, &buf_packet, call DymoPacket.getSize(&buf_packet));
      }
    }
  }

  /* Send a RREP to buf_info */
  task void issueRREP(){
    atomic {
      if(busySend)
	post issueRREP();
      else {
	busySend = TRUE;
	call DymoPacket.createRM(&buf_packet, DYMO_RREP, &me, &buf_info);
	if(buf_target.address)
	  call DymoPacket.addInfo(&buf_packet, &buf_target);
	call AMSend.send(buf_info.nexthop, &buf_packet, call DymoPacket.getSize(&buf_packet));
	buf_target.address = 0;
      }
    }
  }

  /* Send a RERR with buf_info as unreachable */
  task void issueRERR(){
    atomic {
      if(busySend)
	post issueRERR();
      else {
	busySend = TRUE;
	call DymoPacket.createRM(&buf_packet, DYMO_RERR, NULL, &buf_info);
	call AMSend.send(AM_BROADCAST_ADDR, &buf_packet, call DymoPacket.getSize(&buf_packet));
      }
    }
  }

  /* Send current fw_msg to fw_address */
  task void forward(){
    atomic {
      if(busySend)
	post forward();
      else {
	busySend = TRUE;
	call AMSend.send(fw_address, &fw_msg, call DymoPacket.getSize(&fw_msg));
      }
    }
  }

  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
#ifdef DYMO_MONITORING
    signal DymoMonitor.msgReceived(msg);
#endif
    dbg("de", "DE: Message (type %hhu) received.\n", call DymoPacket.getType(msg));
    atomic {
      if(busyProcess){
	dbg("de", "DE: I'm busy, I can't handle this message, sorry.\n");
	return msg; //we discard msg if a message is already being processed
      } else {
	busyProcess = TRUE;
      }
    }
    cur_info_pos = 0;
    fw_address = AM_BROADCAST_ADDR;
    call DymoPacket.startProcessing(msg, &fw_msg);
    return avail_msg;
  }

  event proc_action_t DymoPacket.hopsProcessed(message_t * msg, uint8_t hop_limit, uint8_t hop_count){
    cur_hopcnt = hop_count; //TODO use this
    if(hop_limit == 0){
      fw_address = 0;
      dbg("de", "DE: This message has reached its HL (%hhu hops) => discard.\n", hop_count);
      return ACTION_DISCARD_MSG;
    } else {
      return ACTION_KEEP;
    }
  }

  proc_action_t process_rm_info(message_t * msg, rt_info_t * info){
    cur_info_pos++;
    if(cur_info_pos == 1){ //target

      if(info->address == me.address){

	if(call DymoPacket.getType(msg) == DYMO_RREQ){
	  dbg("de", "DE: This RREQ is for me => RREP.\n");
	  if(info->seqnum < me.seqnum)
	    incr_seqnum();
	  dbg("de", "DE: My seqnum for the RREP: %u.\n", me.seqnum);
	  sendRREP = TRUE; //to send a RREP when we receive the next event (= originator info)
	} else {
	  dbg("de", "DE: This RREP is for me, cool!\n");
	}
	fw_address = 0;
	return ACTION_DISCARD_MSG;

      } else { //not for me

	info->nexthop = call AMPacket.source(msg);
	if(call DymoPacket.getType(msg) == DYMO_RREQ){

#if DYMO_INTER_RREP
	  //if we know a route to the target, we send a intermediate RREP and don't forward the message
	  ignoreNeeded = info->address;
	  if (call RoutingTable.getRoute(info->address, &buf_info) == SUCCESS) {
#if DYMO_FORCE_INTER_RREP
	    if( !info->seqnum || !(call DymoTable.isSuperior(info, DYMO_RREQ)) ){
#else
	    if( info->seqnum && !(call DymoTable.isSuperior(info, DYMO_RREQ)) ){
#endif
	      dbg("de", "DE: This RREQ is for %u, but I know the route => RREP.\n", info->address);
	      dbg("de", "DE: My seqnum for the RREP: %u.\n", me.seqnum);
	      buf_target = buf_info;
	      sendRREP = TRUE;
	      fw_address = 0;
	      return ACTION_DISCARD_MSG;
	    }
	  }
#endif
	  return ACTION_KEEP;

	} else { //RREP

	  ignoreNeeded = info->address;
	  dbg("de", "DE: This RREP is for %u.\n", info->address);
	  if(call RoutingTable.getForwardingRoute(info->address, &buf_info) == SUCCESS){
	    fw_address = buf_info.nexthop;
	    return ACTION_KEEP;
	  } else {
	    fw_address = 0;
	    return ACTION_DISCARD_MSG;
	  }

	}//end RREP

      }//end not for me

    } else if((call DymoPacket.getType(msg) == DYMO_RREQ) //end if(info==target)
	      && (cur_info_pos == 2)
	      && (info->address == me.address)){

      fw_address = 0;
      sendRREP = FALSE;
      return ACTION_DISCARD_MSG;

    } else {

      info->nexthop = call AMPacket.source(msg);
      if(call DymoTable.update(info, call DymoPacket.getType(msg)) == EINVAL){

	if(cur_info_pos == 2){ //origin
	  dbg("de", "DE: I am discarding a msg with a bad origin (%u-%u-%hhu)\n", info->address, info->seqnum, info->hopcnt);
	  fw_address = 0;
	  return ACTION_DISCARD_MSG;
	} else {               //Additional info
	  dbg("de", "DE: I am discarding a bad piece of info (%u-%u-%hhu)\n", info->address, info->seqnum, info->hopcnt);
	  return ACTION_DISCARD;
	}

      } else {

	if((cur_info_pos == 2) && sendRREP){
	  buf_info = *info;
	  atomic {
	    if(!busyIssue){
	      busyIssue = 1;
	      post issueRREP();
	    }
	  }
	  sendRREP = 0;
	}

#ifdef DYMO_MONITORING 
	if( rreq_time    //TODO probably misses a test
	    && (cur_info_pos == 2)
	    && (call DymoPacket.getType(msg) == DYMO_RREP) ) {
	  rreq_time = (call Timer.getNow()) - rreq_time;
	  signal DymoMonitor.routeDiscovered(rreq_time, info->address);
	  rreq_time = 0;
	}
#endif
	return ACTION_KEEP;

      }

    } //end info!=target
  }//end event

  proc_action_t process_err_info(message_t * msg, rt_info_t * info){
    info->nexthop = call AMPacket.source(msg);
    if(call DymoTable.update(info, call DymoPacket.getType(msg)) == EINVAL){
      return ACTION_DISCARD;       
    } else {
      cur_info_pos++; //we only count kept pieces of info
      return ACTION_KEEP;
    }
  }

  event proc_action_t DymoPacket.infoProcessed(message_t * msg, rt_info_t * info){
    if(call DymoPacket.getType(msg) == DYMO_RERR)
      return process_err_info(msg, info);
    else
      return process_rm_info(msg, info);
  }

  event void DymoPacket.messageProcessed(message_t * msg){
    avail_msg = msg;
    if( (call DymoPacket.getType(msg) == DYMO_RERR) && cur_info_pos ){

      post forward();

    } else if( (call DymoPacket.getType(msg) != DYMO_RERR) && fw_address ){

#if DYMO_APPEND_INFO
      call DymoPacket.addInfo(&fw_msg, me);
#endif
      dbg("de", "DE: I'll forward this RM.\n");
      post forward();

    } else {

      atomic {
	busyProcess = 0;
      }
      dbg("de", "DE: I'm not busy anymore.\n");

    }
    dbg("de", "DE: Message (type %hhu) successfully processed.\n", call DymoPacket.getType(msg));
  }

  event void DymoTable.routeNeeded(addr_t destination){
    if(ignoreNeeded == destination){
      ignoreNeeded = 0;
    } else {
      buf_info.address = destination;
      buf_info.seqnum = 0;
      buf_info.has_hopcnt = FALSE;
      atomic {
	if(!busyIssue){
	  busyIssue = TRUE;
#ifdef DYMO_MONITORING
	  rreq_time = call Timer.getNow();
#endif
	  post issueRREQ();
	}
      }
    }
  }
  
  event void DymoTable.brokenRouteNeeded(const rt_info_t * route_info){
    buf_info = *route_info;
    buf_info.has_hopcnt = FALSE;
    atomic {
      if(!busyIssue){
	busyIssue = TRUE;
	post issueRERR();
      }
    }
  }

  event void RoutingTable.evicted(const rt_info_t * route_info, reason_t r){
    if(r == REASON_UNREACHABLE){
      buf_info = *route_info;
      buf_info.has_hopcnt = FALSE;
      atomic {
	if(!busyIssue){
	  busyIssue = TRUE;
	  post issueRERR();
	}
      }
    }
  }

  event void AMSend.sendDone(message_t *msg, error_t error){
    atomic {
      busySend = FALSE;
    }
    if(msg == &fw_msg){
      atomic{
	busyProcess = FALSE;
      }
    } else if(msg == &buf_packet) {
      atomic {
	busyIssue = FALSE;
      }
    }

    if(error == SUCCESS){
      if(msg == &fw_msg)
	dbg("de", "DE: Message (type %hhu) forwarded.\n", call DymoPacket.getType(msg));
      else
	dbg("de", "DE: Message (type %hhu) sent.\n", call DymoPacket.getType(msg));
    } else
      dbg("de", "DE: Failed to send message (type %hhu).\n", call DymoPacket.getType(msg));

#ifdef DYMO_MONITORING
    if(error == SUCCESS)
      signal DymoMonitor.msgSent(msg);
#endif
  }

  command error_t SplitControl.stop(){ }

#ifdef DYMO_MONITORING

  event void Timer.fired(){}

 default event void DymoMonitor.msgReceived(message_t * msg){}

 default event void DymoMonitor.msgSent(message_t * msg){}

 default event void DymoMonitor.routeDiscovered(uint32_t delay, addr_t target){}

#endif
}

