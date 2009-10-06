/**
 * Copyright (c) 2004,2005 Hewlett-Packard Company
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:

 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * Neither the name of the Hewlett-Packard Company nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.

 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Simple message format for exchanging network data.
 * We use the 'start' index to allow messages to have data
 * prepended.
 *
 * Each message contains a 'next' field, which allows us
 * to maintain queues.
 *
 * Note that we encode 16 and 32 bit values in network byte
 * order, which is MSB (most significant byte) first.
 *
 * However, 802.15.4 multibyte fields are always encoded LSB,
 * or least significant byte first.  The Chipcon radio also
 * stores values LSB, as does the TI MSP processor.
 * This really only shows up when we are setting the PanID and
 * short address of our messages.
 * 
 * @author Andrew Christian
 */

#ifndef _MESSAGE_H
#define _MESSAGE_H


#define MESSAGE_MAX_LENGTH 128

struct Message {
  uint8_t data[ MESSAGE_MAX_LENGTH ];
  uint8_t start;
  uint8_t length;
  struct Message *next;
};

/*
 * this is useful for tracking down allocs w/out frees.  add a uint8_t who to the Message structure and then see who holds
 * all the messages using param...
#ifdef DEBUG_MESSAGE
enum {
  MSG_WHO_FREE=0,
  MSG_WHO_CLIENT_HAWR,
  MSG_WHO_CLIENT_HSNOOZET,
  MSG_WHO_CLIENT_AR,
  MSG_WHO_CLIENT_HSCANT,
  MSG_WHO_CC2420H_DELAYEDRXFIFO,
  MSG_WHO_UIP_SENDMESSAGE,
  MSG_WHO_UIP_SENDUDPMESSAGE  
};
#endif
*/


/**
 * Message manipulation functions.
 *
 * All integers are sent in network byte order - MSB first
 */

inline void msg_set_uint8( struct Message *msg, uint8_t offset, uint8_t data )
{
  uint8_t i = msg->start + offset;
  if ( i >= MESSAGE_MAX_LENGTH ) i -= MESSAGE_MAX_LENGTH;
  msg->data[ i] = data;
}

inline void msg_set_uint16( struct Message *msg, uint8_t offset, uint16_t data )
{
  uint8_t i = msg->start + offset;
  if ( i >= MESSAGE_MAX_LENGTH ) i -= MESSAGE_MAX_LENGTH;
  msg->data[i] = (data & 0xff00) >> 8;
  if ( ++i >= MESSAGE_MAX_LENGTH ) i -= MESSAGE_MAX_LENGTH;
  msg->data[i] = (data & 0xff);
}

inline void msg_set_saddr( struct Message *msg, uint8_t offset, uint16_t data )
{
  uint8_t i = msg->start + offset;
  if ( i >= MESSAGE_MAX_LENGTH ) i -= MESSAGE_MAX_LENGTH;
  msg->data[i] = (data & 0xff);
  if ( ++i >= MESSAGE_MAX_LENGTH ) i -= MESSAGE_MAX_LENGTH;
  msg->data[i] = (data & 0xff00) >> 8;
}

inline void msg_set_uint32( struct Message *msg, uint8_t offset, uint32_t data )
{
  uint8_t i = msg->start + offset;
  if ( i >= MESSAGE_MAX_LENGTH ) i -= MESSAGE_MAX_LENGTH;
  msg->data[i] = (data & 0xff000000) >> 24;
  if ( ++i >= MESSAGE_MAX_LENGTH ) i -= MESSAGE_MAX_LENGTH;
  msg->data[i] = (data & 0x00ff0000) >> 16;
  if ( ++i >= MESSAGE_MAX_LENGTH ) i -= MESSAGE_MAX_LENGTH;
  msg->data[i] = (data & 0x0000ff00) >> 8;
  if ( ++i >= MESSAGE_MAX_LENGTH ) i -= MESSAGE_MAX_LENGTH;
  msg->data[i] = (data & 0xff);
}

inline void msg_set_buf( struct Message *msg, uint8_t offset, const uint8_t *buf, uint8_t len )
{
  uint8_t i = msg->start + offset;
  for ( ; len ; len--, i++ ) {
    if ( i >= MESSAGE_MAX_LENGTH ) i -= MESSAGE_MAX_LENGTH;
    msg->data[i] = *buf++;
  }
}

inline uint8_t msg_get_uint8( const struct Message *msg, uint8_t offset )
{
  uint8_t i = msg->start + offset;
  if ( i >= MESSAGE_MAX_LENGTH ) i -= MESSAGE_MAX_LENGTH;
  return msg->data[ i ];
}

inline int8_t msg_get_int8( const struct Message *msg, uint8_t offset )
{
  uint8_t i = msg->start + offset;
  if ( i >= MESSAGE_MAX_LENGTH ) i -= MESSAGE_MAX_LENGTH;
  return ((int8_t *)(msg->data))[ i ];
}

inline uint16_t msg_get_uint16( const struct Message *msg, uint8_t offset )
{
  uint8_t i = msg->start + offset;
  uint16_t result;

  if ( i >= MESSAGE_MAX_LENGTH ) i -= MESSAGE_MAX_LENGTH;
  result = (msg->data[i] << 8);
  if ( ++i >= MESSAGE_MAX_LENGTH ) i -= MESSAGE_MAX_LENGTH;
  result |= msg->data[i];
  return result;
}

inline uint16_t msg_get_saddr( const struct Message *msg, uint8_t offset )
{
  uint8_t i = msg->start + offset;
  uint16_t result;

  if ( i >= MESSAGE_MAX_LENGTH ) i -= MESSAGE_MAX_LENGTH;
  result = msg->data[i];
  if ( ++i >= MESSAGE_MAX_LENGTH ) i -= MESSAGE_MAX_LENGTH;
  result |= (msg->data[i] << 8);
  return result;
}

inline void msg_get_buf( const struct Message *msg, uint8_t offset, uint8_t *buf, uint8_t len )
{
  uint8_t i = msg->start + offset;
  for ( ; len ; len--, i++ ) {
    if ( i >= MESSAGE_MAX_LENGTH ) i -= MESSAGE_MAX_LENGTH;
    *buf++ = msg->data[i];
  }
}

inline void msg_get_str( const struct Message *msg, uint8_t offset, uint8_t *str, uint8_t len )
{
  uint8_t i = msg->start + offset;
  if ( i >= MESSAGE_MAX_LENGTH ) i -= MESSAGE_MAX_LENGTH;

  while (--len && msg->data[i] ) {
    *str++ = msg->data[i++];
    if ( i >= MESSAGE_MAX_LENGTH ) i -= MESSAGE_MAX_LENGTH;
  }

  *str = 0;
}

inline bool msg_cmp_buf( const struct Message *msg, uint8_t offset, const uint8_t *buf, uint8_t len )
{
  uint8_t i = msg->start + offset;
  for ( ; len ; len--, i++ ) {
    if ( i >= MESSAGE_MAX_LENGTH ) i -= MESSAGE_MAX_LENGTH;
    if ( *buf++ != msg->data[i])
      return FALSE;
  }
  return TRUE;
}

inline bool msg_cmp_str( const struct Message *msg, uint8_t offset, const uint8_t *buf )
{
  uint8_t i = msg->start + offset;
  while (1) {
    if ( i >= MESSAGE_MAX_LENGTH ) i -= MESSAGE_MAX_LENGTH;
    if ( *buf++ != msg->data[i])
      return FALSE;
    if ( msg->data[i] == 0 )
      return TRUE;
    i++;
  }
  return TRUE;
}

inline void msg_append_uint8( struct Message *msg, uint8_t data )
{
  uint8_t i = msg->start + msg->length;
  if ( i >= MESSAGE_MAX_LENGTH ) i -= MESSAGE_MAX_LENGTH;
  
  msg->data[ i ] = data;
  msg->length++;
}

inline void msg_append_uint16( struct Message *msg, uint16_t data )
{
  uint8_t i = msg->start + msg->length;
  if ( i >= MESSAGE_MAX_LENGTH ) i -= MESSAGE_MAX_LENGTH;
  msg->data[i] = (data & 0xff00) >> 8;
  if ( ++i >= MESSAGE_MAX_LENGTH ) i -= MESSAGE_MAX_LENGTH;
  msg->data[i] = (data & 0xff);
  msg->length += 2;
}

inline void msg_append_saddr( struct Message *msg, uint16_t data )
{
  uint8_t i = msg->start + msg->length;
  if ( i >= MESSAGE_MAX_LENGTH ) i -= MESSAGE_MAX_LENGTH;
  msg->data[i] = (data & 0xff);
  if ( ++i >= MESSAGE_MAX_LENGTH ) i -= MESSAGE_MAX_LENGTH;
  msg->data[i] = (data & 0xff00) >> 8;
  msg->length += 2;
}

inline void msg_append_uint32( struct Message *msg, uint32_t data )
{
  uint8_t i = msg->start + msg->length;
  if ( i >= MESSAGE_MAX_LENGTH ) i -= MESSAGE_MAX_LENGTH;
  msg->data[i] = (data & 0xff000000) >> 24;
  if ( ++i >= MESSAGE_MAX_LENGTH ) i -= MESSAGE_MAX_LENGTH;
  msg->data[i] = (data & 0x00ff0000) >> 16;
  if ( ++i >= MESSAGE_MAX_LENGTH ) i -= MESSAGE_MAX_LENGTH;
  msg->data[i] = (data & 0x0000ff00) >> 8;
  if ( ++i >= MESSAGE_MAX_LENGTH ) i -= MESSAGE_MAX_LENGTH;
  msg->data[i] = (data & 0xff);
  msg->length += 4;
}

inline void msg_append_buf( struct Message *msg, const uint8_t *buf, uint8_t len )
{
  uint8_t i = msg->start + msg->length;
  msg->length += len;
  for ( ; len ; len--, i++ ) {
    if ( i >= MESSAGE_MAX_LENGTH ) i -= MESSAGE_MAX_LENGTH;
    msg->data[i] = *buf++;
  }
}

inline void msg_append_str( struct Message *msg, const uint8_t *str )
{
  uint8_t i = msg->start + msg->length;
  for ( ; *str ; i++ ) {
    if ( i >= MESSAGE_MAX_LENGTH ) i -= MESSAGE_MAX_LENGTH;
    msg->data[i] = *str++;
    msg->length++;
  }
  if ( i >= MESSAGE_MAX_LENGTH ) i -= MESSAGE_MAX_LENGTH;
  msg->data[i] = 0;
  msg->length++;
}

inline void msg_prepend_uint8( struct Message *msg, uint8_t data )
{
  msg->length++;
  if ( msg->start == 0 )
    msg->start = MESSAGE_MAX_LENGTH - 1;
  else
    msg->start--;

  msg->data[ msg->start ] = data;
}

inline void msg_add_to_front( struct Message *msg, uint8_t count )
{
  if ( msg->start < count )
    msg->start = MESSAGE_MAX_LENGTH - count + msg->start;
  else
    msg->start -= count;
  msg->length += count;
}

inline void msg_drop_from_front( struct Message *msg, uint8_t count )
{
  msg->start  += count;
  if ( msg->start >= MESSAGE_MAX_LENGTH ) msg->start -= MESSAGE_MAX_LENGTH;
  msg->length -= count;
}

inline void msg_add_to_end( struct Message *msg, uint8_t count )
{
  msg->length += count;
}

inline void msg_drop_from_end( struct Message *msg, uint8_t count )
{
  msg->length -= count;
}

inline uint8_t * msg_get_pointer( struct Message *msg, uint8_t offset )
{
  uint8_t i = msg->start + offset;
  if ( i >= MESSAGE_MAX_LENGTH ) i -= MESSAGE_MAX_LENGTH;
  return msg->data + i;
}

inline void msg_clear( struct Message *msg )
{
  msg->length = 0;
  msg->start  = 0;
}

inline void    msg_set_length( struct Message *msg, uint8_t len )  { msg->length = len; }
inline uint8_t msg_get_length( const struct Message *msg )         { return msg->length; }
inline uint8_t msg_get_max_length( void )         { return MESSAGE_MAX_LENGTH; }

/**
 * Message queue functions.  Message queues are simple
 * linked lists.
 */

inline struct Message * pop_queue( struct Message **head )
{
  struct Message *result = *head;
  if ( result != NULL )
    *head = (*head)->next;
  return result;
}

inline void push_queue( struct Message **head, struct Message *item )
{
  item->next = *head;
  *head = item;
}

inline void append_queue( struct Message **head, struct Message *item )
{
  if (*head == NULL) {
    *head = item;
  }
  else {
    struct Message *bm = *head;
    while ( bm->next != NULL )
      bm = bm->next;
    bm->next = item;
  }
  item->next = NULL;
}

inline uint8_t count_queue( struct Message *head )
{
  uint8_t count = 0;
  while ( head ) {
    count++;
    head = head->next;
  }
  return count;
}

#endif // _BASIC_MESSAGE_H
