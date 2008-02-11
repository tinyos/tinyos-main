/*
 * Copyright (c) 2005-2006 Arch Rock Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Arch Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * @author Jonathan Hui <jhui@archrock.com>
 * @author David Moss
 * @author Jung Il Choi
 * @version $Revision: 1.1 $ $Date: 2008-02-11 17:41:25 $
 */
 
#include "printfUART.h"
#include "frame_format.h"
#include "mac_func.h"

module CC2420ReceiveP {

  provides interface Init;
  provides interface StdControl;
  //provides interface CC2420Receive;
  //provides interface Receive;
  //provides interface ReceiveIndicator as PacketIndicator;

  provides interface Receiveframe;
  
  provides interface AddressFilter;



  uses interface GeneralIO as CSN;
  uses interface GeneralIO as FIFO;
  uses interface GeneralIO as FIFOP;
  uses interface GpioInterrupt as InterruptFIFOP;

  uses interface Resource as SpiResource;
  uses interface CC2420Fifo as RXFIFO;
  uses interface CC2420Strobe as SACK;
  uses interface CC2420Strobe as SFLUSHRX;
  //uses interface CC2420Packet;
  //uses interface CC2420PacketBody;
  uses interface CC2420Config;
  
  uses interface Leds;
  
  
  
  
  
}

implementation {

typedef enum{
	S_STOPPED =0,
	S_STARTED=1,
	S_RX_LENGTH=2,
	S_RX_FC=3, //FC - FRAME CONTROL
	S_RX_ADDR=4,
	S_RX_PAYLOAD=5,
	S_RX_DISCARD=6,
}cc2420_receive_state_t;


/*
  typedef enum {
    S_STOPPED,
    S_STARTED,
    S_RX_LENGTH,
    S_RX_FCF,
    S_RX_PAYLOAD,
  } cc2420_receive_state_t;
  */
  enum {
    RXFIFO_SIZE = 128,
    TIMESTAMP_QUEUE_SIZE = 8,
    SACK_HEADER_LENGTH = 7,
  };
  
  //uint16_t m_timestamp_queue[ TIMESTAMP_QUEUE_SIZE ];
  
  //uint8_t m_timestamp_head;
  
  //uint8_t m_timestamp_size;
  
  /** Number of packets we missed because we were doing something else */
  uint8_t m_missed_packets;
  
  /** TRUE if we are receiving a valid packet into the stack */
 bool receivingPacket;
  
  /** The length of the frame we're currently receiving */
  norace uint8_t rxFrameLength;
  
  //number of bytes left in the FIFO Buffer
  norace uint8_t m_bytes_left;
  
  //norace message_t* m_p_rx_buf;

  //message_t m_rx_buf;
  
  //already used
  //cc2420_receive_state_t m_state;
  
  
  norace MPDU rxmpdu;
  MPDU *rxmpdu_ptr;
  
  
   cc2420_receive_state_t m_state;
 
  
  uint8_t rssi;
  
  
  uint8_t receive_count=0;
  
  
  
/*******************************************/
/****	ADDRESS DECODE VARIABLES		****/
/*******************************************/
	//address verification frame control variables
	//frame control variables
	uint8_t source_address=0;
	uint8_t destination_address=0;

	//address verification structure pointers
	dest_short *dest_short_ptr;
	dest_long *dest_long_ptr;

	source_short *source_short_ptr;
	source_long *source_long_ptr;

	beacon_addr_short *beacon_addr_short_ptr;

	uint8_t address_decode = 1;

	//address verification variables
	uint16_t ver_macCoordShortAddress = 0x0000;
	uint16_t ver_macShortAddress = 0xffff;
	
	uint32_t ver_aExtendedAddress0=0x00000000;
	uint32_t ver_aExtendedAddress1=0x00000000;
  
	uint16_t ver_macPANId=0xffff;
    
  
  
  /***************** Prototypes ****************/
  void reset_state();
  void beginReceive();
  void receive();
  void waitForNextPacket();
  void flush();
  
 // task void receiveDone_task();
  
  /***************** Init Commands ****************/
  command error_t Init.init() {
    //m_p_rx_buf = &m_rx_buf;
	
	rxmpdu_ptr = &rxmpdu;
	
	  printfUART_init();
	
    return SUCCESS;
  }

  /***************** StdControl ****************/
  command error_t StdControl.start() {
   
    atomic {
      reset_state();
      m_state = S_STARTED;
      atomic receivingPacket = FALSE;
      call InterruptFIFOP.enableFallingEdge();
    }
	

	
    return SUCCESS;
  }
  
  command error_t StdControl.stop() {
    atomic {
      m_state = S_STOPPED;
      reset_state();
      call CSN.set();
      call InterruptFIFOP.disable();
    }
    return SUCCESS;
  }




	command error_t AddressFilter.set_address(uint16_t mac_short_address, uint32_t mac_extended0, uint32_t mac_extended1)
	{
		
		ver_macShortAddress = mac_short_address;

		ver_aExtendedAddress0=mac_extended0;
		ver_aExtendedAddress1=mac_extended1;

		address_decode = 1;

		//printfUART("sa %i %x %x %x %x\n",address_decode,ver_macShortAddress,ver_aExtendedAddress0,ver_aExtendedAddress1);


		return SUCCESS;
	}
	  
	  
	command error_t AddressFilter.set_coord_address(uint16_t mac_coord_address, uint16_t mac_panid)
	{
   
		ver_macCoordShortAddress = mac_coord_address;
		ver_macPANId = mac_panid;

		//printfUART("sca %i %x %x\n",address_decode,ver_macCoordShortAddress,ver_macPANId);

		return SUCCESS;
	}
   
   
	command error_t AddressFilter.enable_address_decode(uint8_t enable)
	{
	
		address_decode = enable;
		
		//printfUART("ead %i\n",address_decode);
	
		return SUCCESS;
	}
	



  /***************** Receive Commands ****************/
  /*
  command void* Receive.getPayload(message_t* m, uint8_t* len) {
  
    if (len != NULL) {
      *len = ((uint8_t*) (call CC2420PacketBody.getHeader( m_p_rx_buf )))[0];
    }
    return m->data;
  }

  command uint8_t Receive.payloadLength(message_t* m) {
    uint8_t* buf = (uint8_t*)(call CC2420PacketBody.getHeader( m_p_rx_buf ));
    return buf[0];
  }
  
  */
  /***************** CC2420Receive Commands ****************/
  /**
   * Start frame delimiter signifies the beginning/end of a packet
   * See the CC2420 datasheet for details.
   */
   /*
  async command void CC2420Receive.sfd( uint16_t time ) {
  
    if ( m_timestamp_size < TIMESTAMP_QUEUE_SIZE ) {
      uint8_t tail =  ( ( m_timestamp_head + m_timestamp_size ) % 
                        TIMESTAMP_QUEUE_SIZE );
      m_timestamp_queue[ tail ] = time;
      m_timestamp_size++;
    }
	
  }

  async command void CC2420Receive.sfd_dropped() {
  
    if ( m_timestamp_size ) {
      m_timestamp_size--;
    }
	
  }
*/
  /***************** PacketIndicator Commands ****************/
  /*
  command bool PacketIndicator.isReceiving() {
    bool receiving;
    atomic {
      receiving = receivingPacket;
    }
    return receiving;
  }
  
  */
  /***************** InterruptFIFOP Events ****************/
  async event void InterruptFIFOP.fired() {
  
  ////printfUART("Int %i\n",m_state);
//call Leds.led1Toggle();
  //call Leds.led2Toggle();
    
	
	if ( m_state == S_STARTED ) {
	
	
      beginReceive();
	  
	  
	  /*
	if(call SpiResource.isOwner()) {
      receive();
      
    } else if (call SpiResource.immediateRequest() == SUCCESS) {
      receive();
      
    } else {
      call SpiResource.request();
    }
*/
    } else {
      m_missed_packets++;
    }
	
  }
  
  
  /***************** SpiResource Events ****************/
  event void SpiResource.granted() {
    receive();
  }
  
  /***************** RXFIFO Events ****************/
  /**
   * We received some bytes from the SPI bus.  Process them in the context
   * of the state we're in.  Remember the length byte is not part of the length
   */
  async event void RXFIFO.readDone( uint8_t* rx_buf, uint8_t rx_len,error_t error ) {
  
  
  //int i;
	/*
	uint8_t len;
	
	//uint8_t rssi;
	//uint8_t lqi;
	int i;
	
	len = rx_buf[0];
	
	rssi= 255 - rx_buf[len-1];
	
	//lqi = rssi & 0x7f;
	*/
	/*
  
   //printfUART("r d %i %i\n", len, rssi);
  
   // len = rx_buf[0];
	//rssi=rx_buf[len-2];
 
	
	for (i=0;i<40;i++)
	{
		//printfUART("r %i %x\n",i,rx_buf[i]);
	}
 
 
 
 
  	//signal Receiveframe.receive((uint8_t*)rxmpdu_ptr, rssi);
	
	receive_count++;
	
	if (receive_count == 2)
	{	flush();
		receive_count =0;
	}
	*/
	
	atomic{
	//my code
	switch(m_state){
	
	case S_RX_LENGTH:
	
					rxFrameLength = rx_buf[0];
					
					m_state = S_RX_FC;
					
					//verify print
					////printfUART("LEN %x %x %i %i\n",rxFrameLength,rxmpdu_ptr->length,m_state,m_bytes_left);
					
					//printfUART("r%i %i %i\n",rxmpdu_ptr->seq_num,rxFrameLength,MAC_PACKET_SIZE);
					
					if ( rxFrameLength + 1 > m_bytes_left )
					{
						// Length of this packet is bigger than the RXFIFO, flush it out.
						//printfUART("pkt too big\n","");
						flush();
						
					}
					else
					{
						if ( !call FIFO.get() && !call FIFOP.get() )
						{
						//printfUART("RED left %x\n",m_bytes_left);
					
						  m_bytes_left -= rxFrameLength + 1;
						}
						
						//if(rxFrameLength <= MAC_PACKET_SIZE) 
						//{
							if(rxFrameLength > 0) 
							{
								//verify read length and read the frame control field (2 bytes)
								if(rxFrameLength > 2) {
								  // This packet has an FCF byte plus at least one more byte to read
								  //call RXFIFO.continueRead(buf + 1, SACK_HEADER_LENGTH);
								  
								  ////printfUART("LEN OK\n","");
								  //read frame control + sequence number
								  call RXFIFO.continueRead((uint8_t*)rxmpdu_ptr + 1, 3);
								}
								else
								{
								  // This is really a bad packet, skip FCF and get it out of here.
								  //m_state = S_RX_PAYLOAD;
								  
									m_state = S_RX_DISCARD;
									//printfUART("bad len\n","");
									
									call RXFIFO.continueRead((uint8_t*)rxmpdu_ptr + 1, rxFrameLength);
									return;
								}
							} 
							else 
							{
								// Length == 0; start reading the next packet
								atomic receivingPacket = FALSE;
								call CSN.set();
								call SpiResource.release();
								waitForNextPacket();
							}
						  
						//}
						//else
						//{
							// Length is too large; we have to flush the entire Rx FIFO
						//	//printfUART("pkt too large\n","");
						//	flush();
							
						//	return;
						//}
					}
					break;
	case S_RX_FC:
					
					//verify print
					////printfUART("FC %x %x %x %i\n",rxmpdu_ptr->frame_control1,rxmpdu_ptr->frame_control2,rxmpdu_ptr->seq_num, m_state);
				
					if ((rxmpdu_ptr->frame_control1 & 0x7) == TYPE_ACK)
					{
						m_state = S_RX_PAYLOAD;
						
						//printfUART("r ack \n",""); 
						call RXFIFO.continueRead((uint8_t*)rxmpdu_ptr+4,2);
						return;
					}
					
				
					if (address_decode == 1)
					{
						m_state = S_RX_ADDR;
						
						destination_address=get_fc2_dest_addr(rxmpdu_ptr->frame_control2);
						
						if (destination_address > 1)
						{
							switch(destination_address)
							{
								case SHORT_ADDRESS:
												//read the short address + destination PAN identifier
												////printfUART("s ad",""); 
												call RXFIFO.continueRead((uint8_t*)rxmpdu_ptr + 4, 6); 
													break;
								
								case LONG_ADDRESS:
												//read the long address + destination PAN identifier
												call RXFIFO.continueRead((uint8_t*)rxmpdu_ptr + 4, 12);
												break;
							}
						}
						else
						{
							//destination address fields not present
							m_state = S_RX_PAYLOAD;
							//it is not possible to do the address decoding, there is no destination address fields
							//send the full packet up
							call RXFIFO.continueRead((uint8_t*)rxmpdu_ptr + 4, rxmpdu_ptr->length- 3);
							
						}
					}
					else
					{
						//address decode is not activated
						m_state = S_RX_PAYLOAD;
						call RXFIFO.continueRead((uint8_t*)rxmpdu_ptr + 4, rxmpdu_ptr->length - 3);
					}
	
	
					break;			
	case S_RX_ADDR:
					m_state = S_RX_PAYLOAD;
					
					
					switch ((rxmpdu_ptr->frame_control1 & 0x7))
					{
						case TYPE_BEACON:
									////printfUART("RB \n","");
									
									beacon_addr_short_ptr = (beacon_addr_short *) &rxmpdu_ptr->data[0];
									
									////printfUART("pb %x %x %x %x\n",rxmpdu_ptr->seq_num, beacon_addr_short_ptr->destination_PAN_identifier,beacon_addr_short_ptr->destination_address, beacon_addr_short_ptr->source_address);
																		
									/*
									for (i=0;i<6;i++)
									{
										//printfUART("r %i %x %x %x\n",i,rxmpdu_ptr->data[i],rx_buf[i],rx_buf[i+4]);
									}
									*/
									
									//printfUART("RB %x %x \n",ver_macCoordShortAddress,ver_macShortAddress);

									
									//avoid VERIFY static assignment of coordinator parent
									if (beacon_addr_short_ptr->source_address != ver_macCoordShortAddress)
									{
											//printfUART("bad bec %x %x\n", beacon_addr_short_ptr->source_address,ver_macCoordShortAddress);
											
											m_state = S_RX_DISCARD;
											call RXFIFO.continueRead((uint8_t*)rxmpdu_ptr + 10, rxmpdu_ptr->length - 9);
											return;
									}
									/*
									if (ver_macShortAddress != 0xffff)
									{
										if ( beacon_addr_short_ptr->source_address != ver_macShortAddress)
										{
											//printfUART("pb %x %x\n", beacon_addr_short_ptr->source_address,ver_macShortAddress);
											
											m_state = S_RX_DISCARD;
											call RXFIFO.continueRead((uint8_t*)rxmpdu_ptr + 10, rxmpdu_ptr->length - 9);
											return;
										}
									}
									*/
									break;
							case TYPE_DATA:
							case TYPE_CMD:
							
									//VALIDATION OF DESTINATION ADDRESSES - NOT TO OVERLOAD THE PROCESSOR
									if (destination_address > 1)
									{
										switch(destination_address)
										{
											case SHORT_ADDRESS: 
													dest_short_ptr = (dest_short *) &rxmpdu_ptr->data[0];
																
													if ( dest_short_ptr->destination_address != 0xffff && dest_short_ptr->destination_address != ver_macShortAddress)
													{
														//printfUART("nsm %x %x\n", dest_short_ptr->destination_address,ver_macShortAddress); 
														
														m_state = S_RX_DISCARD;
														call RXFIFO.continueRead((uint8_t*)rxmpdu_ptr + 10, rxmpdu_ptr->length - 9);
														return;
													}
													
													//If a destination PAN identifier is included in the frame, it shall match macPANId or shall be the
													//broadcast PAN identifier (0 x ffff).
													if(dest_short_ptr->destination_PAN_identifier != 0xffff && dest_short_ptr->destination_PAN_identifier != ver_macPANId )
													{
														//printfUART("wsP %x %x \n", dest_short_ptr->destination_PAN_identifier,ver_macPANId); 
														
														m_state = S_RX_DISCARD;
														call RXFIFO.continueRead((uint8_t*)rxmpdu_ptr + 10, rxmpdu_ptr->length - 9);
														return;
													}
													
													break;
											
											case LONG_ADDRESS: 
													
													dest_long_ptr = (dest_long *) &rxmpdu_ptr->data[0];
													/*
													if ( dest_long_ptr->destination_address0 !=ver_aExtendedAddress0 && dest_long_ptr->destination_address1 !=ver_aExtendedAddress1 )
													{
														//printfUART("nlm %x %x \n",dest_long_ptr->destination_address0,dest_long_ptr->destination_address1); 
														
														m_state = S_RX_DISCARD;
														call RXFIFO.continueRead((uint8_t*)rxmpdu_ptr + 16, rxmpdu_ptr->length - 15);
														return;
													}
													
													
													//If a destination PAN identifier is included in the frame, it shall match macPANId or shall be the
													//broadcast PAN identifier (0 x ffff).
													if(dest_long_ptr->destination_PAN_identifier != 0xffff && dest_long_ptr->destination_PAN_identifier != ver_macPANId )
													{
														//printfUART("wLP %x %x\n", dest_long_ptr->destination_PAN_identifier,ver_macPANId); 
																	
														m_state = S_RX_DISCARD;
														call RXFIFO.continueRead((uint8_t*)rxmpdu_ptr + 16, rxmpdu_ptr->length - 15);
														return;
													}
													*/
													break;
										}
									}
									
									break;
									
							case TYPE_ACK:
							
										//printfUART("error ack \n",""); 
										//call RXFIFO.continueRead((uint8_t*)rxmpdu_ptr);
										
										return;
										
									break;
									

					}
					
					//read the remaining packet
					switch(destination_address)
					{
						case SHORT_ADDRESS:
							////printfUART("as %i\n", (rxmpdu_ptr->length - 9));
								
							call RXFIFO.continueRead((uint8_t*)rxmpdu_ptr + 10, rxmpdu_ptr->length - 9); //7
							break;
								
						case LONG_ADDRESS:
							////printfUART("al %i\n", (rxmpdu_ptr->length - 15));
							call RXFIFO.continueRead((uint8_t*)rxmpdu_ptr + 16, rxmpdu_ptr->length - 15);
							break;
					}
			
			break;
					
					
	case S_RX_PAYLOAD:
				call CSN.set();
				//signal Receiveframe.receive((uint8_t*)rxmpdu_ptr, rssi);
				
				
				//rssi= 255 - rx_buf[len-1];
				
				/*
				for (i=6;i<12;i++)
				{
					//printfUART("p %i %x %x\n",i,rxmpdu_ptr->data[i],rx_buf[i-6]);
				}
				*/
				
				if(!m_missed_packets) {
					// Release the SPI only if there are no more frames to download
					call SpiResource.release();
				}
				
				rssi = 255 - rxmpdu_ptr->data[rxmpdu_ptr->length-4];
				
				//printfUART("pay %i %x %i\n",rxmpdu_ptr->seq_num, rssi,m_missed_packets);
				
				signal Receiveframe.receive((uint8_t*)rxmpdu_ptr, rssi);
				
				
				if (m_missed_packets == 0)
				{
					flush();
				}
				else
				{
					waitForNextPacket();
				}
				
			break;
	
	
	case S_RX_DISCARD:
			atomic receivingPacket = FALSE;
			call CSN.set();
			call SpiResource.release();	
				if (m_missed_packets == 0)
				{
					flush();
				}
				else
				{
					waitForNextPacket();
				}
				
			break;
				
	default:
			  atomic receivingPacket = FALSE;
			  call CSN.set();
			  call SpiResource.release();
			  break;
	
	
	}
  
  }
  
  
  /*
    cc2420_header_t* header = call CC2420PacketBody.getHeader( m_p_rx_buf );
    cc2420__t* metadata = call CC2420PacketBody.getMetadata( m_p_rx_buf );
    uint8_t* buf = (uint8_t*) header;
    rxFrameLength = buf[ 0 ];

    switch( m_state ) {

    case S_RX_LENGTH:
      m_state = S_RX_FCF;
      if ( rxFrameLength + 1 > m_bytes_left ) {
        // Length of this packet is bigger than the RXFIFO, flush it out.
        flush();
        
      } else {
        if ( !call FIFO.get() && !call FIFOP.get() ) {
          m_bytes_left -= rxFrameLength + 1;
        }
        
        if(rxFrameLength <= MAC_PACKET_SIZE) {
          if(rxFrameLength > 0) {
            if(rxFrameLength > SACK_HEADER_LENGTH) {
              // This packet has an FCF byte plus at least one more byte to read
              call RXFIFO.continueRead(buf + 1, SACK_HEADER_LENGTH);
              
            } else {
              // This is really a bad packet, skip FCF and get it out of here.
              m_state = S_RX_PAYLOAD;
              call RXFIFO.continueRead(buf + 1, rxFrameLength);
            }
                            
          } else {
            // Length == 0; start reading the next packet
            atomic receivingPacket = FALSE;
            call CSN.set();
            call SpiResource.release();
            waitForNextPacket();
          }
          
        } else {
          // Length is too large; we have to flush the entire Rx FIFO
          flush();
        }
      }
      break;
      
    case S_RX_FCF:
      m_state = S_RX_PAYLOAD;
      
      /*
       * The destination address check here is not completely optimized. If you 
       * are seeing issues with dropped acknowledgements, try removing
       * the address check and decreasing SACK_HEADER_LENGTH to 2.
       * The length byte and the FCF byte are the only two bytes required
       * to know that the packet is valid and requested an ack.  The destination
       * address is useful when we want to sniff packets from other transmitters
       * while acknowledging packets that were destined for our local address.
       *//*
      if(call CC2420Config.isAutoAckEnabled() && !call CC2420Config.isHwAutoAckDefault()) {
        if (((( header->fcf >> IEEE154_FCF_ACK_REQ ) & 0x01) == 1)
            && (header->dest == call CC2420Config.getShortAddr())
            && ((( header->fcf >> IEEE154_FCF_FRAME_TYPE ) & 7) == IEEE154_TYPE_DATA)) {
          // CSn flippage cuts off our FIFO; SACK and begin reading again
          call CSN.set();
          call CSN.clr();
          call SACK.strobe();
          call CSN.set();
          call CSN.clr();
          call RXFIFO.beginRead(buf + 1 + SACK_HEADER_LENGTH, 
              rxFrameLength - SACK_HEADER_LENGTH);
          return;
        }
		
		
      }
      
      // Didn't flip CSn, we're ok to continue reading.
      call RXFIFO.continueRead(buf + 1 + SACK_HEADER_LENGTH, 
          rxFrameLength - SACK_HEADER_LENGTH);
      break;
    
    case S_RX_PAYLOAD:
      call CSN.set();
      
      if(!m_missed_packets) {
        // Release the SPI only if there are no more frames to download
        call SpiResource.release();
      }
      
      if ( m_timestamp_size ) {
        if ( rxFrameLength > 10 ) {
          metadata->time = m_timestamp_queue[ m_timestamp_head ];
          m_timestamp_head = ( m_timestamp_head + 1 ) % TIMESTAMP_QUEUE_SIZE;
          m_timestamp_size--;
        }
      } else {
        metadata->time = 0xffff;
      }
      
      // We may have received an ack that should be processed by Transmit
      // buf[rxFrameLength] >> 7 checks the CRC
      if ( ( buf[ rxFrameLength ] >> 7 ) && rx_buf ) {
        uint8_t type = ( header->fcf >> IEEE154_FCF_FRAME_TYPE ) & 7;
       // signal CC2420Receive.receive( type, m_p_rx_buf );
        if ( type == IEEE154_TYPE_DATA ) {
          post receiveDone_task();
          return;
        }
      }
      
      waitForNextPacket();
      break;

    default:
      atomic receivingPacket = FALSE;
      call CSN.set();
      call SpiResource.release();
      break;
      
    }
    */
  }

  async event void RXFIFO.writeDone( uint8_t* tx_buf, uint8_t tx_len, error_t error ) {
  }  
  
  /***************** Tasks *****************/
  /**
   * Fill in metadata details, pass the packet up the stack, and
   * get the next packet.
   */
   /*
  task void receiveDone_task() {
    cc2420_metadata_t* metadata = call CC2420PacketBody.getMetadata( m_p_rx_buf );
    uint8_t* buf = (uint8_t*) call CC2420PacketBody.getHeader( m_p_rx_buf );;
    
    metadata->crc = buf[ rxFrameLength ] >> 7;
    metadata->rssi = buf[ rxFrameLength - 1 ];
    metadata->lqi = buf[ rxFrameLength ] & 0x7f;
    m_p_rx_buf = signal Receive.receive( m_p_rx_buf, m_p_rx_buf->data, 
                                         rxFrameLength );

    atomic receivingPacket = FALSE;
    waitForNextPacket();
  }
  */
  /****************** CC2420Config Events ****************/
  event void CC2420Config.syncDone( error_t error ) {
  }
  
  /****************** Functions ****************/
  /**
   * Attempt to acquire the SPI bus to receive a packet.
   */
   
  void beginReceive() { 
  
    m_state = S_RX_LENGTH;
    
    atomic receivingPacket = TRUE;
  
  ////printfUART("br %i\n",m_state);

	if(call SpiResource.isOwner()) {
      receive();
      
    } else if (call SpiResource.immediateRequest() == SUCCESS) {
      receive();
      
    } else {
      call SpiResource.request();
    }
  }
  
  /**
   * Flush out the Rx FIFO
   */
  void flush() {
	//printfUART("f %i\n",m_state);
    reset_state();
    call CSN.set();
    call CSN.clr();
    call SFLUSHRX.strobe();
    call SFLUSHRX.strobe();
    call CSN.set();
    call SpiResource.release();
    waitForNextPacket();
  }
  
  /**
   * The first byte of each packet is the length byte.  Read in that single
   * byte, and then read in the rest of the packet.  The CC2420 could contain
   * multiple packets that have been buffered up, so if something goes wrong, 
   * we necessarily want to flush out the FIFO unless we have to.
   */
  void receive() {
	//call Leds.led2Toggle();
  
    call CSN.clr();
    
	//call RXFIFO.beginRead( (uint8_t*)(call CC2420PacketBody.getHeader( m_p_rx_buf )), 1 );
  
	//call RXFIFO.beginRead ((uint8_t*)rxmpdu_ptr,100);
  
	//my old
	call RXFIFO.beginRead((uint8_t*)rxmpdu_ptr,1);
	
	

  
  }


  /**
   * Determine if there's a packet ready to go, or if we should do nothing
   * until the next packet arrives
   */
   
  void waitForNextPacket() {
    atomic {
      if ( m_state == S_STOPPED ) {
        call SpiResource.release();
        return;
      }
      
	   //printfUART("wn %i %i\n",m_state,m_missed_packets );
	  
	  
      atomic receivingPacket = FALSE;
	  
      if ( ( m_missed_packets && call FIFO.get() ) || !call FIFOP.get() ) {
        // A new packet is buffered up and ready to go
        if ( m_missed_packets ) {
          m_missed_packets--;
        }
        
        beginReceive();
        
      } else {
        // Wait for the next packet to arrive
		
		
		
        m_state = S_STARTED;
		
		//printfUART("wnP %i\n",m_state);
		
        m_missed_packets = 0;
        call SpiResource.release();
      }
    }
  }
 
  /**
   * Reset this component
   */
   
  void reset_state() {
    m_bytes_left = RXFIFO_SIZE;
    atomic receivingPacket = FALSE;
    //m_timestamp_head = 0;
    //m_timestamp_size = 0;
    m_missed_packets = 0;
  }

}
