#include <sim_gain.h>
#include <sim_tossim.h>

module CC2420ActiveMessageC {
  provides interface CC2420Packet as Packet;
  uses interface AMPacket as SubPacket;
}
implementation {

  /**
   * Get transmission power setting for current packet.
   *
   * @param the message
   */
  async command uint8_t Packet.getPower( message_t* p_msg ) {
    return 1;
  }

  /**
   * Set transmission power for a given packet. Valid ranges are
   * between 0 and 31.
   *
   * @param p_msg the message.
   * @param power transmission power.
   */
  async command void Packet.setPower( message_t* p_msg, uint8_t power ) {
    return;
  }
  
  /**
   * Get rssi value for a given packet. For received packets, it is
   * the received signal strength when receiving that packet. For sent
   * packets, it is the received signal strength of the ack if an ack
   * was received.
   */
  
  async command int8_t Packet.getRssi( message_t* p_msg ) {
    uint16_t src = call SubPacket.source(p_msg);
    return (int)sim_gain_value(src, TOS_NODE_ID);
  }

  /**
   * Get lqi value for a given packet. For received packets, it is the
   * link quality indicator value when receiving that packet. For sent
   * packets, it is the link quality indicator value of the ack if an
   * ack was received.
   */
  
  async command uint8_t Packet.getLqi( message_t* p_msg ) {
    uint16_t src = call SubPacket.source(p_msg);
    int sig = (int)sim_gain_value(src, TOS_NODE_ID);
    if (sig > -60) {
      sig = 110;
    }
    else {
      sig = 230 + (sig * 2);
      sig += (sim_random() % 10);
    }
    
    return (uint8_t)sig;
  }
  
}
