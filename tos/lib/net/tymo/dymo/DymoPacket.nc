/*
 * Copyright (c) 2007 Romain Thouvenin <romain.thouvenin@gmail.com>
 * Published under the terms of the GNU General Public License (GPLv2).
 */

#include "routing_table.h"

/**
 * DymoPacket - Interface to manipulate DYMO packets.
 *
 * @author Romain Thouvenin
 */

interface DymoPacket {

  /*****************
   * Packet header *
   *****************/

  /**
   * Type of the packet.
   * @return DYMO_RREQ, DYMO_RREP or DYMO_RERR
   */
  command dymo_msg_t getType(message_t * msg);

  /**
   * Size of the packet (all fields included).
   */
  command uint16_t getSize(message_t * msg);


  /*********************
   * Creating a packet *
   *********************/

  /**
   * Create a routing message.  This is not strictly a Routing Message
   * as defined by DYMO specs: this is also the command to create a
   * RERR.
   * @param msg the buffer to fill
   * @param msg_type The type of message (RREQ, RREP or RERR)
   * @param origin The originator of the routing message, should be NULL for a RERR
   * @param target The target of the routing message, or first unreachable node for a RERR
   */
  command void createRM(message_t * msg, dymo_msg_t msg_type, 
			const rt_info_t * origin, const rt_info_t * target);

  /**
   * Append additional information to a message.  This is up to the
   * implementation to choose where in the message the information
   * should be added. In anycase, it must not be added before the
   * target and originator.
   * @param msg the existing message 
   * @param info The piece of information to append @return
   * @return ESIZE if the payload has reached its maximum size<br/>
   *         SUCCESS otherwise
   */
  command error_t addInfo(message_t * msg, const rt_info_t * info);


  /***********************
   * Processing a packet *
   ***********************/

  /**
   * Start the processing task of a DYMO message.  Currently, the only
   * way to access the content of a message is to read it entirely
   * with this command. It will report all information found thanks to
   * events above.
   * @param msg The message to process
   * @param newmsg The message that will contain the processed message
   * to be forwarded. May be NULL if such a message is not wanted.
   */
  command void startProcessing(message_t * msg, message_t * newmsg);

  /**
   * Hop values have been extracted from the processed packet.
   * @param msg the message being processed
   * @param hop_limit the (decremented) hop limit value of the message
   * @param hop_count the (incremented) hop count value of the message
   * @return ACTION_DISCARD_MSG if a building a message to be forwarded
   * is not wanted anymore (typically when hop_limit==0), 
   * anything else otherwise.
   */
  event proc_action_t hopsProcessed(message_t * msg, uint8_t hop_limit, uint8_t hop_count);

  /**
   * A piece of routing information has been extracted from the processed packet.
   * @param msg the message being processed
   * @param info the extracted piece of information. If present, hopcnt has been decremented.
   * @return ACTION_KEEP to keep this information in the forwarded message<br/>
   *         ACTION_DISCARD to remove this information in the forwardedmessage<br/>
   *         ACTION_DISCARD_MSG to cancel the creation of the forwarded message.
   */
  event proc_action_t infoProcessed(message_t * msg, rt_info_t * info);

  /**
   * Processing task finished.
   * No further processing event will be signaled for this message.
   */
  event void messageProcessed(message_t * msg);
}
