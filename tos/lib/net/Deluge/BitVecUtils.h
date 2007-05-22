/*
 * "Copyright (c) 2000-2004 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * Provides generic methods for manipulating bit vectors.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 */

#ifndef __BITVEC_UTILS_H__
#define __BITVEC_UTILS_H__

#define BIT_GET(x, i) ((x) & (1 << (i)))
#define BIT_SET(x, i) ((x) | (1 << (i)))
#define BIT_CLEAR(x, i) ((x) & ~(1 << (i)))

#define BITVEC_GET(x, i) (BIT_GET((x)[(i)/8], (i)%8))
#define BITVEC_SET(x, i) ((x)[(i)/8] = BIT_SET((x)[(i)/8], (i)%8))
#define BITVEC_CLEAR(x, i) ((x)[(i)/8] = BIT_CLEAR((x)[(i)/8], (i)%8))

#endif
