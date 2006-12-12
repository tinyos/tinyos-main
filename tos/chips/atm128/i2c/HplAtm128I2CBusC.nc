/// $Id: HplAtm128I2CBusC.nc,v 1.4 2006-12-12 18:23:03 vlahan Exp $

/*
 *  Copyright (c) 2004-2006 Crossbow Technology, Inc.
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
 * This driver implements direct I2C register access and a blocking master
 * controller for the ATmega128 via a Hardware Platform Layer (HPL) to its  
 * two-wire-interface (TWI) hardware subsystem.
 *
 * @author Martin Turon <mturon@xbow.com>
 * @author Philip Levis
 *
 * @version    $Id: HplAtm128I2CBusC.nc,v 1.4 2006-12-12 18:23:03 vlahan Exp $
 */

configuration HplAtm128I2CBusC {
  provides interface HplAtm128I2CBus as I2C;
}
implementation {

  components HplAtm128GeneralIOC as IO, HplAtm128I2CBusP as Bus;
  
  I2C         = Bus.I2C;
  Bus.I2CClk  -> IO.PortD0;
  Bus.I2CData -> IO.PortD1;
}
