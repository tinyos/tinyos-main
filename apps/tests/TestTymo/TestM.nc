#include "routing_table.h"

module TestM {
  
  uses {
    interface Boot;
    interface Leds;
    interface SplitControl;
    interface AMPacket as MHPacket;
    interface Packet;
    interface Receive;
    interface Intercept;
    interface AMSend as MHSend;
    interface Timer<TMilli>;
  }
#ifdef DYMO_MONITORING
  uses interface DymoMonitor;
#endif
}

implementation {

  message_t packet;

  enum {
    ORIGIN = 1,
    TARGET = 3,
  };

  void display(message_t * msg){
    uint8_t * payload = NULL;
    uint8_t size;
    int8_t i;
    dbg("messages", "message content:\n");
    for(i=0; i<size; i+=4, payload+=4){
      dbg("messages", "\t%hhu\t%hhu\t%hhu\t%hhu\n", *payload, *(payload+1), *(payload+2), *(payload+3));
    }
  }

  void setLeds(uint16_t val) {
    if (val & 0x01)
      call Leds.led0Toggle();
    if (val & 0x02)
      call Leds.led1Toggle();
    if (val & 0x04)
      call Leds.led2Toggle();
  }

  task void stop(){
    call SplitControl.stop();
  }

  event void Boot.booted(){
    call SplitControl.start();
  }

  event void SplitControl.startDone(error_t e){
    if(call MHPacket.address() == ORIGIN){
      call Timer.startPeriodic(2048);
    }
  }

  event void Timer.fired(){
    nx_uint16_t * payload = call Packet.getPayload(&packet, 2);
    error_t error;
    *payload = 1664;
    error = call MHSend.send(TARGET, &packet, sizeof(*payload));
    if(error == SUCCESS){
      dbg("messages", "Sending a beer...\n");
    } else {
      dbg("messages", "Unable to send the beer! - %hhu\n", error);
    }
  }

  event void MHSend.sendDone(message_t * msg, error_t e){
    if((e == SUCCESS) && (msg == &packet) && (call MHPacket.address() == ORIGIN)){
      dbg("messages", "Beer successfully sent.\n");
      setLeds(1);
    } else if (e == FAIL) {
      dbg("messages", "Sending the beer didn't succeed!\n");
      setLeds(2);
    } else {
      dbg("messages", "What the hell is going on!?");
    }
  }
  
  event message_t * Receive.receive(message_t * msg, void * payload, uint8_t len){
    if(call MHPacket.address() == TARGET){
      dbg("messages", "I have received a message from %u\n", call MHPacket.source(msg));
      dbg("messages", "It is a %u french beer, great! :o)\n", *(nx_uint16_t *)payload);
      setLeds(4);
    } else {
      dbg("messages", "What is this message?\n");
    }
    return msg;
  }

  event bool Intercept.forward(message_t * msg, void * payload, uint8_t len){
    setLeds(2);
    return TRUE;
  }

  event void SplitControl.stopDone(error_t e){}

#ifdef DYMO_MONITORING

  event void DymoMonitor.msgReceived(message_t * msg){
    dbg("messages", "Dymo msg received.\n");
  }

  event void DymoMonitor.msgSent(message_t * msg){
    dbg("messages", "Dymo msg sent.\n");
  }

  event void DymoMonitor.routeDiscovered(uint32_t delay, addr_t target){
    dbg("messages", "Route for %u discovered in %lu milliseconds.\n", target, delay);
  }

#endif

}
