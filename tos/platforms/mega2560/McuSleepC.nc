// $Id: McuSleepC.nc,v 1.4 2006-12-12 18:23:44 vlahan Exp $
/*
 * Copyright (c) 2005-2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

module McuSleepC {
	provides {
		interface McuSleep;
		interface McuPowerState;
	}
	uses {
		interface McuPowerOverride;
	}
}

implementation {
	async command void McuPowerState.update() {
	}

	async command void McuSleep.sleep() {
	}

	default async command mcu_power_t McuPowerOverride.lowestState() {
		return ATM128_POWER_DOWN;
	}
}

