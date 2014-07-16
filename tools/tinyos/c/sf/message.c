/* Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/* Authors:  David Gay  <dgay@intel-research.net>
 *           Intel Research Berkeley Lab
 */

#include <stdlib.h>
#include "message.h"

struct tmsg {
  uint8_t *data;
  size_t len;
};

tmsg_t *new_tmsg(void *packet, size_t len)
{
  tmsg_t *x = malloc(sizeof(tmsg_t));

  if (x)
    {
      x->data = packet;
      x->len = len;
    }
  return x;
}

void free_tmsg(tmsg_t *msg)
{
  if (msg)
    free(msg);
}

void reset_tmsg(tmsg_t *msg, void *packet, size_t len)
{
  if (!msg)
    return;
  msg->data = packet;
  msg->len  = len;
}

void *tmsg_data(tmsg_t *msg)
{
  return msg->data;
}

size_t tmsg_length(tmsg_t *msg)
{
  return msg->len;
}

static void (*failfn)(void);

void tmsg_fail(void)
{
  if (failfn)
    failfn();
}

void (*tmsg_set_fail(void (*fn)(void)))(void)
{
  void (*oldfn)(void) = failfn;

  failfn = fn;

  return oldfn;
}

/* Check if a specified bit field is in range for a buffer, and invoke
   tmsg_fail if not. Return TRUE if in range, FALSE otherwise */
static int boundsp(tmsg_t *msg, size_t offset, size_t length)
{
  if (offset + length <= msg->len * 8)
    return 1;

  tmsg_fail();
  return 0;
}

/* Convert 2's complement 'length' bit integer 'x' from unsigned to signed
 */
static int64_t u2s(uint64_t x, size_t length)
{
  if (x & 1ULL << (length - 1))
    return (int64_t)x - (1LL << length);
  else
    return x;
}

uint64_t tmsg_read_ule(tmsg_t *msg, size_t offset, size_t length)
{
  uint64_t x = 0;

  if (boundsp(msg, offset, length))
    {
      size_t byte_offset = offset >> 3;
      size_t bit_offset = offset & 7;
      size_t shift = 0;

      /* all in one byte case */
      if (length + bit_offset <= 8)
	return (msg->data[byte_offset] >> bit_offset) & ((1 << length) - 1);

      /* get some high order bits */
      if (offset > 0)
	{
	  x = msg->data[byte_offset] >> bit_offset;
	  byte_offset++;
	  shift += 8 - bit_offset;
	  length -= 8 - bit_offset;
	}

      while (length >= 8)
	{
	  x |= (uint64_t)msg->data[byte_offset++] << shift;
	  shift += 8;
	  length -= 8;
	}

      /* data from last byte */
      if (length > 0)
	x |= (uint64_t)(msg->data[byte_offset] & ((1 << length) - 1)) << shift;
    }

  return x;
}

int64_t tmsg_read_le(tmsg_t *msg, size_t offset, size_t length)
{
  return u2s(tmsg_read_ule(msg, offset, length), length);
}

void tmsg_write_ule(tmsg_t *msg, size_t offset, size_t length, uint64_t x)
{
  if (boundsp(msg, offset, length))
    {
      size_t byte_offset = offset >> 3;
      size_t bit_offset = offset & 7;
      size_t shift = 0;

      /* all in one byte case */
      if (length + bit_offset <= 8)
	{
	  msg->data[byte_offset] = 
	    ((msg->data[byte_offset] & ~(((1 << length) - 1) << bit_offset))
	     | x << bit_offset);
	  return;
	}

      /* set some high order bits */
      if (bit_offset > 0)
	{
	  msg->data[byte_offset] =
	    ((msg->data[byte_offset] & ((1 << bit_offset) - 1)) | x << bit_offset);
	  byte_offset++;
	  shift += 8 - bit_offset;
	  length -= 8 - bit_offset;
	}

      while (length >= 8)
	{
	  msg->data[byte_offset++] = x >> shift;
	  shift += 8;
	  length -= 8;
	}

      /* data for last byte */
      if (length > 0)
	msg->data[byte_offset] = 
	  (msg->data[byte_offset] & ~((1 << length) - 1)) | x >> shift;
    }
}

void tmsg_write_le(tmsg_t *msg, size_t offset, size_t length, int64_t value)
{
  tmsg_write_ule(msg, offset, length, value);
}

uint64_t tmsg_read_ube(tmsg_t *msg, size_t offset, size_t length)
{
  uint64_t x = 0;

  if (boundsp(msg, offset, length))
    {
      size_t byte_offset = offset >> 3;
      size_t bit_offset = offset & 7;

      /* All in one byte case */
      if (length + bit_offset <= 8)
	return (msg->data[byte_offset] >> (8 - bit_offset - length)) &
	  ((1 << length) - 1);

      /* get some high order bits */
      if (bit_offset > 0)
	{
	  length -= 8 - bit_offset;
	  x = (uint64_t)(msg->data[byte_offset] & ((1 << (8 - bit_offset)) - 1)) << length;
	  byte_offset++;
	}

      while (length >= 8)
	{
	  length -= 8;
	  x |= (uint64_t)msg->data[byte_offset++] << length;
	}

      /* data from last byte */
      if (length > 0)
	x |= msg->data[byte_offset] >> (8 - length);

      return x;
    }

  return x;
}

int64_t tmsg_read_be(tmsg_t *msg, size_t offset, size_t length)
{
  return u2s(tmsg_read_ube(msg, offset, length), length);
}

void tmsg_write_ube(tmsg_t *msg, size_t offset, size_t length, uint64_t x)
{
  if (boundsp(msg, offset, length))
    {
      size_t byte_offset = offset >> 3;
      size_t bit_offset = offset & 7;

      /* all in one byte case */
      if (length + bit_offset <= 8) {
	size_t mask = ((1 << length) - 1) << (8 - bit_offset - length);

	msg->data[byte_offset] = 
	  ((msg->data[byte_offset] & ~mask) | x << (8 - bit_offset - length));
	return;
      }

      /* set some high order bits */
      if (bit_offset > 0)
	{
	  size_t mask = (1 << (8 - bit_offset)) - 1;

	  length -= 8 - bit_offset;
	  msg->data[byte_offset] = 
	    ((msg->data[byte_offset] & ~mask) | x >> length);
	  byte_offset++;
	}

      while (length >= 8)
	{
	  length -= 8;
	  msg->data[byte_offset++] = x >> length;
	}

      /* data for last byte */
      if (length > 0)
	{
	  size_t mask = (1 << (8 - length)) - 1;

	  msg->data[byte_offset] =
	    ((msg->data[byte_offset] & mask) | x << (8 - length));
	}
    }
}

void tmsg_write_be(tmsg_t *msg, size_t offset, size_t length, int64_t value)
{
  tmsg_write_ube(msg, offset, length, value);
}

/* u2f and f2u convert raw 32-bit values to/from float. This code assumes
   that the floating point rep in the uint32_t values:
     bit 31: sign, bits 30-23: exponent, bits 22-0: mantissa
   matches that of a floating point value when such a value is stored in
   memory.
*/

/* Note that C99 wants us to use the union approach rather than the
   cast-a-pointer approach... */
union f_and_u {
  uint32_t u;
  float f;
};

static float u2f(uint32_t x)
{
  union f_and_u y = { .u = x};
  return y.f;
}

static uint32_t f2u(float x)
{
  union f_and_u y = { .f = x};
  return y.u;
}

float tmsg_read_float_le(tmsg_t *msg, size_t offset)
{
  return u2f(tmsg_read_ule(msg, offset, 32));
}

void tmsg_write_float_le(tmsg_t *msg, size_t offset, float x)
{
  tmsg_write_ule(msg, offset, 32, f2u(x));
}

float tmsg_read_float_be(tmsg_t *msg, size_t offset)
{
  return u2f(tmsg_read_ube(msg, offset, 32));
}

void tmsg_write_float_be(tmsg_t *msg, size_t offset, float x)
{
  tmsg_write_ube(msg, offset, 32, f2u(x));
}
