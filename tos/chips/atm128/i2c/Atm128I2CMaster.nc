/// $Id: Atm128I2CMaster.nc,v 1.4 2006-12-12 18:23:03 vlahan Exp $

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

#include "Atm128I2C.h"

/**
 * Interface for non-blocking I2C master engine.
 *
 * @author Martin Turon <mturon@xbow.com>
 */
interface Atm128I2CMaster
{
    /** Ping the I2C device. */
    command error_t ping  ();

    /** Write the given data buffer the I2C device. */
    command error_t write (uint8_t *data, uint8_t length);

    /** Read from the I2C device. */
    command error_t read  (uint8_t *data, uint8_t length);

    /** Signal that the ping to the I2C device is done. */
    event void pingDone  (error_t result);

    /** Signal that the read from the I2C device is done. */
    event void readDone  ();

    /** Signal that the write to the I2C device is done. */
    event void writeDone ();
}
