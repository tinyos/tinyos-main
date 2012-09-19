/*
 * option.h -- helpers for handling options in CoAP PDUs
 *
 * Copyright (C) 2010,2011 Olaf Bergmann <bergmann@tzi.org>
 *
 * This file is part of the CoAP library libcoap. Please see
 * README for terms of use. 
 */

/**
 * @file option.h
 * @brief helpers for handling options in CoAP PDUs
 */

#ifndef _OPTION_H_
#define _OPTION_H_

#include "bits.h"
#include "pdu.h"

/** 
 * Use byte-oriented access methods here because sliding a complex
 * struct coap_opt_t over the data buffer may cause bus error on
 * certain platforms.
 */ 
typedef unsigned char coap_opt_t;
#define PCHAR(p) ((coap_opt_t *)(p))

#define COAP_OPT_ISEXTENDED(opt) ((*PCHAR(opt) & 0x0f) == 0x0f)

/* these macros should be used to access fields from coap_opt_t */
#define COAP_OPT_DELTA(opt) (*PCHAR(opt) >> 4)
#define COAP_OPT_SETDELTA(opt,val)			\
  (*PCHAR(opt) = (*PCHAR(opt) & 0x0f) | ((val) << 4))

#define COAP_OPT_LENGTH(opt)					\
  ((unsigned int)(COAP_OPT_ISEXTENDED(opt)			\
		  ? (*(PCHAR(opt) + 1) + 15)			\
		  : (*PCHAR(opt) & 0x0f)))

#define COAP_OPT_SETLENGTH(opt,val)					\
  if ((val) < 15)							\
    *PCHAR(opt) = ((*PCHAR(opt) & 0xf0) | ((val) & 0x0f));		\
  else {								\
    *PCHAR(opt) |= 0x0f;						\
    *(PCHAR(opt) + 1) = ((val) - 15) & 0xff;				\
  }

#define COAP_OPT_VALUE(opt)				\
  (PCHAR(opt) + (COAP_OPT_ISEXTENDED(opt) ? 2 : 1))

/* Do not forget to adjust this when coap_opt_t is changed! */
#define COAP_OPT_SIZE(opt) ( COAP_OPT_LENGTH(opt) + ( COAP_OPT_ISEXTENDED(opt) ? 2: 1 ) )

/**
 * Calculates the beginning of the PDU's option section.
 * @hideinitializer
 */
#define options_start(p) \
  ((coap_opt_t *) ( (unsigned char *)p->hdr + sizeof (coap_hdr_t) ))

/**
 * Interprets @p opt as pointer to a CoAP option and advances to
 * the next byte past this option.
 * @hideinitializer
 */
#define options_next(opt) \
  ((coap_opt_t *)((unsigned char *)(opt) + COAP_OPT_SIZE(opt)))

/**
 * @defgroup opt_filter Option Filters
 * @{
 */

/** 
 * Fixed-size bit-vector we use for option filtering. It is large
 * enough to hold the highest option number known at build time (20 in
 * the core spec).
 */
typedef unsigned char coap_opt_filter_t[(COAP_MAX_OPT >> 3) + 1];

/** Pre-defined filter that includes all options. */
extern const coap_opt_filter_t COAP_OPT_ALL;

/** 
 * Clears filter @p f.
 * 
 * @param f The filter to clear.
 */
static inline void
coap_option_filter_clear(coap_opt_filter_t f) {
  memset(f, 0, sizeof(coap_opt_filter_t));
}

/** 
 * Sets the corresponding bit for @p type in @p filter. This function
 * returns @c 1 if bit was set or @c -1 on error (i.e. when the given
 * type does not fit in the filter).
 * 
 * @param filter The filter object to change.
 * @param type   The type for which the bit should be set. 
 * 
 * @return @c 1 if bit was set, @c -1 otherwise.
 */
inline static int
coap_option_setb(coap_opt_filter_t filter, unsigned char type) {
  return bits_setb((uint8_t *)filter, sizeof(coap_opt_filter_t), type);
}

/** 
 * Clears the corresponding bit for @p type in @p filter. This function
 * returns @c 1 if bit was cleared or @c -1 on error (i.e. when the given
 * type does not fit in the filter).
 * 
 * @param filter The filter object to change.
 * @param type   The type for which the bit should be cleared. 
 * 
 * @return @c 1 if bit was set, @c -1 otherwise.
 */
inline static int
coap_option_clrb(coap_opt_filter_t filter, unsigned char type) {
  return bits_clrb((uint8_t *)filter, sizeof(coap_opt_filter_t), type);
}

/** 
 * Gets the corresponding bit for @p type in @p filter. This function
 * returns @c 1 if the bit is set @c 0 if not, or @c -1 on error (i.e.
 * when the given type does not fit in the filter).
 * 
 * @param filter The filter object to read bit from..
 * @param type   The type for which the bit should be read.
 * 
 * @return @c 1 if bit was set, @c 0 if not, @c -1 on error.
 */
inline static int
coap_option_getb(const coap_opt_filter_t filter, unsigned char type) {
  return bits_getb((uint8_t *)filter, sizeof(coap_opt_filter_t), type);
}

/** 
 * Iterator to run through PDU options. This object must be
 * initialized with coap_option_iterator_init(). Call
 * coap_option_next() to walk through the list of options.
 *
 * @code
 * coap_opt_t *option;
 * coap_opt_iterator_t opt_iter;
 * coap_option_iterator_init(pdu, &opt_iter, COAP_OPT_ALL);
 *
 * while ((option = coap_option_next(&opt_iter))) {
 *   ... do something with option ...
 * }
 * @endcode
 */
typedef struct {
  unsigned char n;		/**< number of the current option */
  unsigned char optcnt;		/**< number of options in the pdu */
  unsigned short type;		/**< decoded option type */
  coap_opt_filter_t filter;	/**< option filter */
  coap_opt_t *option;		/**< pointer to the current option */
} coap_opt_iterator_t;

/** 
 * Initializes the given option iterator @p oi to point to the
 * beginning of the @p pdu's option list. This function returns @p oi
 * on success, @c NULL otherwise (i.e. when no options exist).
 * 
 * @param pdu  The PDU the options of which should be walked through.
 * @param oi   An iterator object that will be initilized.
 * @param filter An optional option type filter. 
 *               With @p type != @c COAP_OPT_ALL, coap_option_next() 
 *               will return only options matching this bitmask. 
 *               Fence-post options @c 14, @c 28, @c 42, ... are always
 *               skipped.
 * 
 * @return The iterator object @p oi on success, @c NULL otherwise.
 */
coap_opt_iterator_t *coap_option_iterator_init(coap_pdu_t *pdu,
     coap_opt_iterator_t *oi, const coap_opt_filter_t filter);

/** 
 * Updates the iterator @p oi to point to the next option. This
 * function returns a pointer to that option or @c NULL if no more
 * options exist. The contents of @p oi will be updated. In
 * particular, @c oi->n specifies the current option's ordinal number
 * (counted from @c 1), @c oi->type is the option's type code, and @c
 * oi->option points to the beginning of the current option
 * itself. When advanced past the last option, @c oi->option will be
 * @c NULL.
 * 
 * Note that options are skipped whose corresponding bits in the
 * filter specified with coap_option_iterator_init() are @c 0. Options
 * with type codes that do not fit in this filter hence will always be
 * returned.
 * 
 * @param oi The option iterator to update.
 * 
 * @return The next option or @c NULL if no more options exist.
 */
coap_opt_t *coap_option_next(coap_opt_iterator_t *oi);

/** 
 * Retrieves the first option of type @p type from @p pdu. @p oi must
 * point to a coap_opt_iterator_t object that will be initialized by
 * this function to filter only options with code @p type. This
 * function returns the first option with this type, or @c NULL if not
 * found.
 * 
 * @param pdu  The PDU to parse for options.
 * @param type The option type code to search for.
 * @param oi   An iterator object to use.
 * 
 * @return A pointer to the first option of type @p type, or @c NULL 
 *         if not found.
 */
coap_opt_t *coap_check_option(coap_pdu_t *pdu, 
			      unsigned char type, 
			      coap_opt_iterator_t *oi);

/** @} */

#endif /* _OPTION_H_ */
