/// $Id: HplMsp430InterruptSig.nc,v 1.1 2008-04-17 22:38:34 klueska Exp $

/*
 *  Copyright (c) 2004-2005 Crossbow Technology, Inc.
 *  All rights reserved.
 *
 *  Permission to use, copy, modify, and distribute this software and its
 *  documentation for any purpose, without fee, and without written
 *  agreement is hereby granted, provided that the above copyright
 *  notice, the (updated) modification history and the author appear in
 *  all copies of this source code.
 *
 *  Permission is also granted to distribute this software under the
 *  standard BSD license as contained in the TinyOS distribution.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS `AS IS'
 *  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
 *  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 *  ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS 
 *  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
 *  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE, DATA, 
 *  OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
 *  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF 
 *  THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * Interface to an Msp430 external interrupt pin that exposes just the
 * interrupt vector routine for easy linking to generic components (see
 * Msp430InterruptSigP for the full interface).
 *
 * @author Martin Turon <mturon@xbow.com>
 * @author Kevin Klues <klueska@cs.stanford.edu>
 * @see Msp430InterruptSigP
 */
interface HplMsp430InterruptSig
{
  /**
   * Signalled when an interrupt occurs on a pin
   */
  inline async event void fired();
}

