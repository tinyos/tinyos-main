/*
 * Copyright (c) 2011 Stanford University
 * All rights reserved.
 *
 * Copyright (c) 2015, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the University of California nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *  Philip Levis <pal@cs.stanford.edu>
 *
 * @author Tim Bormann <code@tkn.tu-berlin.de>
 * @author Jasper Büsch <code@tkn.tu-berlin.de>
 * @author Moksha Birk <code@tkn.tu-berlin.de>
 */

#include "IeeeEui64.h"
#include "MMAC.h"

module LocalIeeeEui64C {
  provides interface LocalIeeeEui64;
} implementation {
  command ieee_eui64_t LocalIeeeEui64.getId() {
    /* This code uses UC Berkeley's OUI; Berkeley
     * allows it to be used as long as bytes 3 and
     * 4 are 'LO' for local. */
    ieee_eui64_t id;

    tsExtAddr addr;
    vMMAC_GetMacAddress(&addr);
    id.data[7] = (addr.u32L >> 0) & 0xff;
    id.data[6] = (addr.u32L >> 8) & 0xff;
    id.data[5] = (addr.u32L >> 16) & 0xff;
    id.data[4] = (addr.u32L >> 24) & 0xff;
    id.data[3] = (addr.u32H >> 0) & 0xff;
    id.data[2] = (addr.u32H >> 8) & 0xff;
    id.data[1] = (addr.u32H >> 16) & 0xff;
    id.data[0] = (addr.u32H >> 24) & 0xff;

    return id;
  }
}
