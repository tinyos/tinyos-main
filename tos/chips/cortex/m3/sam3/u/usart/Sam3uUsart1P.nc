#include <sam3uusarthardware.h>
module Sam3uUsart1P {
  provides interface Sam3uUsart;
  uses interface HplSam3uUsartControl as HplUsart;
  uses interface Leds;
}

implementation{

  uint32_t mode_register = AT91C_US_USMODE_NORMAL
    | AT91C_US_CLKS_CLOCK
    | AT91C_US_ASYNC
    | AT91C_US_CHRL_8_BITS
    | AT91C_US_PAR_NONE
    | AT91C_US_NBSTOP_1_BIT
    | AT91C_US_CHMODE_NORMAL;

  bool STREAM = FALSE;
  uint8_t total_send_length, current_length_position;
  uint8_t *sending_data_ptr;

  command void Sam3uUsart.start(){
    call HplUsart.init();
    call HplUsart.configure(mode_register, 38400 /*9600*/);

    call HplUsart.enableTx();
    call HplUsart.enableRx();

    signal Sam3uUsart.startDone(SUCCESS);
  }

  command error_t Sam3uUsart.stop(){    
    call HplUsart.disableTx();
    call HplUsart.disableRx();

    signal Sam3uUsart.stopDone(SUCCESS);
  }

  command void Sam3uUsart.sendStream(void* msg, uint8_t length){
    // send data byte by byte
    uint8_t data;
    total_send_length = length;
    current_length_position = 0;
    STREAM = TRUE;
    sending_data_ptr = msg;
    data = sending_data_ptr[0];
    call HplUsart.write(0, data, 0);
  }

  command void Sam3uUsart.send(uint8_t data){
    // send data byte by byte
    STREAM = FALSE;
    call HplUsart.write(0, data, 0);
  }

  command void Sam3uUsart.listen(void* msg, uint8_t length){
  }

  event void HplUsart.writeDone(){
    current_length_position ++ ;
    if(!STREAM){
      signal Sam3uUsart.sendDone(SUCCESS);
      return;
    }else {
      current_length_position ++ ;
      if(total_send_length > current_length_position){
	call HplUsart.write(0, (uint8_t)sending_data_ptr[current_length_position], 0);
      }else{
	STREAM = FALSE;
	signal Sam3uUsart.sendDone(SUCCESS);
	return;
      }
    }
  }

  event void HplUsart.readDone(uint8_t data){
    signal Sam3uUsart.receive(SUCCESS, data);
  }



 default event void Sam3uUsart.sendDone(error_t error){}
 default event void Sam3uUsart.receive(error_t error, uint8_t data){}
 default event void Sam3uUsart.startDone(error_t error){}
 default event void Sam3uUsart.stopDone(error_t error){}

}